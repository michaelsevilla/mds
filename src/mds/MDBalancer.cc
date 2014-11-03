// -*- mode:C++; tab-width:8; c-basic-offset:2; indent-tabs-mode:t -*-
// vim: ts=8 sw=2 smarttab
/*
 * Ceph - scalable distributed file system
 *
 * Copyright (C) 2004-2006 Sage Weil <sage@newdream.net>
 *
 * This is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License version 2.1, as published by the Free Software
 * Foundation.  See file COPYING.
 *
 */

#include "mdstypes.h"

#include "MDBalancer.h"
#include "MDS.h"
#include "mon/MonClient.h"
#include "MDSMap.h"
#include "CInode.h"
#include "CDir.h"
#include "MDCache.h"
#include "Migrator.h"

#include "include/Context.h"
#include "msg/Messenger.h"
#include "messages/MHeartbeat.h"
#include "messages/MMDSLoadTargets.h"

#include <fstream>
#include <iostream>
#include <vector>
#include <map>
using std::map;
using std::vector;

#include "common/config.h"

#define dout_subsys ceph_subsys_mds
#undef DOUT_COND
#define DOUT_COND(cct, l) l<=cct->_conf->debug_mds || l <= cct->_conf->debug_mds_balancer
#undef dout_prefix
#define dout_prefix *_dout << "mds." << mds->get_nodeid() << ".bal "

#define MIN_LOAD    50   //  ??
#define MIN_REEXPORT 5  // will automatically reexport
#define MIN_OFFLOAD 10   // point at which i stop trying, close enough


/* This function DOES put the passed message before returning */
int MDBalancer::proc_message(Message *m)
{
  switch (m->get_type()) {

  case MSG_MDS_HEARTBEAT:
    handle_heartbeat(static_cast<MHeartbeat*>(m));
    break;

  default:
    dout(1) << " balancer unknown message " << m->get_type() << dendl;
    assert(0);
    m->put();
    break;
  }

  return 0;
}




void MDBalancer::tick()
{
  static int num_bal_times = g_conf->mds_bal_max;
  static utime_t first = ceph_clock_now(g_ceph_context);
  utime_t now = ceph_clock_now(g_ceph_context);
  utime_t elapsed = now;
  elapsed -= first;

  // sample?
  if ((double)now - (double)last_sample > g_conf->mds_bal_sample_interval) {
    dout(15) << "tick last_sample now " << now << dendl;
    last_sample = now;
  }

  // balance?
  if (last_heartbeat == utime_t())
    last_heartbeat = now;
  if (mds->get_nodeid() == 0 &&
      g_conf->mds_bal_interval > 0 &&
      (num_bal_times ||
       (g_conf->mds_bal_max_until >= 0 &&
	elapsed.sec() > g_conf->mds_bal_max_until)) &&
      mds->is_active() &&
      now.sec() - last_heartbeat.sec() >= g_conf->mds_bal_interval) {
    last_heartbeat = now;
    dout(0) << "mds" << mds->get_nodeid() << " sample=" << now.sec() << "... thu-THUMP" << dendl;
    send_heartbeat();
    num_bal_times--;
  }

  // hash?
  if ((g_conf->mds_bal_frag || g_conf->mds_thrash_fragments) &&
      g_conf->mds_bal_fragment_interval > 0 &&
      now.sec() - last_fragment.sec() > g_conf->mds_bal_fragment_interval) {
    last_fragment = now;
    do_fragmenting();
  }
}




class C_Bal_SendHeartbeat : public MDSInternalContext {
public:
  C_Bal_SendHeartbeat(MDS *mds_) : MDSInternalContext(mds_) { }
  virtual void finish(int f) {
    mds->balancer->send_heartbeat();
  }
};


double mds_load_t::mds_load()
{
  switch(g_conf->mds_bal_mode) {
  case 0:
    return
      .8 * auth.meta_load() +
      .2 * all.meta_load() +
      req_rate +
      10.0 * queue_len;

  case 1:
    return req_rate + 10.0*queue_len;

  case 2:
    return cpu_load_avg;

  }
  assert(0);
  return 0;
}

mds_load_t MDBalancer::get_load(utime_t now)
{
  mds_load_t load(now);

  if (mds->mdcache->get_root()) {
    list<CDir*> ls;
    mds->mdcache->get_root()->get_dirfrags(ls);
    for (list<CDir*>::iterator p = ls.begin();
	 p != ls.end();
	 ++p) {
      load.auth.add(now, mds->mdcache->decayrate, (*p)->pop_auth_subtree_nested);
      load.all.add(now, mds->mdcache->decayrate, (*p)->pop_nested);
    }
  } else {
    dout(20) << "get_load no root, no load" << dendl;
  }

  load.req_rate = mds->get_req_rate();
  load.queue_len = mds->messenger->get_dispatch_queue_len();

  ifstream cpu("/proc/loadavg");
  if (cpu.is_open())
    cpu >> load.cpu_load_avg;

  dout(15) << "get_load " << load << dendl;
  return load;
}

void MDBalancer::send_heartbeat()
{
  utime_t now = ceph_clock_now(g_ceph_context);
  
  if (mds->mdsmap->is_degraded()) {
    dout(10) << "send_heartbeat degraded" << dendl;
    return;
  }

  if (!mds->mdcache->is_open()) {
    dout(5) << "not open" << dendl;
    mds->mdcache->wait_for_open(new C_Bal_SendHeartbeat(mds));
    return;
  }

  mds_load.clear();
  if (mds->get_nodeid() == 0)
    beat_epoch++;

  // my load
  mds_load_t load = get_load(now);
  map<int, mds_load_t>::value_type val(mds->get_nodeid(), load);
  mds_load.insert(val);

  // import_map -- how much do i import from whom
  map<int, float> import_map;
  set<CDir*> authsubs;
  mds->mdcache->get_auth_subtrees(authsubs);
  for (set<CDir*>::iterator it = authsubs.begin();
       it != authsubs.end();
       ++it) {
    CDir *im = *it;
    int from = im->inode->authority().first;
    if (from == mds->get_nodeid()) continue;
    if (im->get_inode()->is_stray()) continue;
    import_map[from] += im->pop_auth_subtree.meta_load(now, mds->mdcache->decayrate);
  }
  mds_import_map[ mds->get_nodeid() ] = import_map;


  dout(5) << "mds." << mds->get_nodeid() << " epoch " << beat_epoch << " load " << load << dendl;
  for (map<int, float>::iterator it = import_map.begin();
       it != import_map.end();
       ++it) {
    dout(5) << "  import_map from " << it->first << " -> " << it->second << dendl;
  }


  set<int> up;
  mds->get_mds_map()->get_mds_set(up);
  for (set<int>::iterator p = up.begin(); p != up.end(); ++p) {
    if (*p == mds->get_nodeid())
      continue;
    MHeartbeat *hb = new MHeartbeat(load, beat_epoch);
    hb->get_import_map() = import_map;
    mds->messenger->send_message(hb,
                                 mds->mdsmap->get_inst(*p));
  }
}

/* This function DOES put the passed message before returning */
void MDBalancer::handle_heartbeat(MHeartbeat *m)
{
  typedef map<int, mds_load_t> mds_load_map_t;

  int who = m->get_source().num();
  dout(25) << "=== got heartbeat " << m->get_beat() << " from " << m->get_source().num() << " " << m->get_load() << dendl;

  if (!mds->is_active())
    goto out;

  if (!mds->mdcache->is_open()) {
    dout(10) << "opening root on handle_heartbeat" << dendl;
    mds->mdcache->wait_for_open(new C_MDS_RetryMessage(mds, m));
    return;
  }

  if (mds->mdsmap->is_degraded()) {
    dout(10) << " degraded, ignoring" << dendl;
    goto out;
  }

  if (who == 0) {
    dout(20) << " from mds0, new epoch" << dendl;
    beat_epoch = m->get_beat();
    send_heartbeat();

    show_imports();
  }

  {
    // set mds_load[who]
    mds_load_map_t::value_type val(who, m->get_load());
    pair < mds_load_map_t::iterator, bool > rval (mds_load.insert(val));
    if (!rval.second) {
      rval.first->second = val.second;
    }
  }
  mds_import_map[ who ] = m->get_import_map();

  //dout(0) << "  load is " << load << " have " << mds_load.size() << dendl;

  {
    unsigned cluster_size = mds->get_mds_map()->get_num_in_mds();
    if (mds_load.size() == cluster_size) {
      // let's go!
      //export_empties();  // no!
      prep_rebalance(m->get_beat());
    }
  }

  // done
 out:
  m->put();
}


void MDBalancer::export_empties()
{
  dout(5) << "export_empties checking for empty imports" << dendl;

  for (map<CDir*,set<CDir*> >::iterator it = mds->mdcache->subtrees.begin();
       it != mds->mdcache->subtrees.end();
       ++it) {
    CDir *dir = it->first;
    if (!dir->is_auth() ||
	dir->is_ambiguous_auth() ||
	dir->is_freezing() ||
	dir->is_frozen())
      continue;

    if (!dir->inode->is_base() &&
	!dir->inode->is_stray() &&
	dir->get_num_head_items() == 0)
      mds->mdcache->migrator->export_empty_import(dir);
  }
}



double MDBalancer::try_match(int ex, double& maxex,
                             int im, double& maxim)
{
  if (maxex <= 0 || maxim <= 0) return 0.0;

  double howmuch = MIN(maxex, maxim);
  if (howmuch <= 0) return 0.0;

  dout(5) << "   - mds." << ex << " exports " << howmuch << " to mds." << im << dendl;

  if (ex == mds->get_nodeid())
    my_targets[im] += howmuch;

  exported[ex] += howmuch;
  imported[im] += howmuch;

  maxex -= howmuch;
  maxim -= howmuch;

  return howmuch;
}

void MDBalancer::queue_split(CDir *dir)
{
  split_queue.insert(dir->dirfrag());
}

void MDBalancer::queue_merge(CDir *dir)
{
  merge_queue.insert(dir->dirfrag());
}

void MDBalancer::do_fragmenting()
{
  if (split_queue.empty() && merge_queue.empty()) {
    dout(20) << "do_fragmenting has nothing to do" << dendl;
    return;
  }

  if (!split_queue.empty()) {
    dout(10) << "do_fragmenting " << split_queue.size() << " dirs marked for possible splitting" << dendl;

    set<dirfrag_t> q;
    q.swap(split_queue);

    for (set<dirfrag_t>::iterator i = q.begin();
	 i != q.end();
	 ++i) {
      CDir *dir = mds->mdcache->get_dirfrag(*i);
      if (!dir ||
	  !dir->is_auth())
	continue;

      dout(10) << "do_fragmenting splitting " << *dir << dendl;
      mds->mdcache->split_dir(dir, g_conf->mds_bal_split_bits);
    }
  }

  if (!merge_queue.empty()) {
    dout(10) << "do_fragmenting " << merge_queue.size() << " dirs marked for possible merging" << dendl;

    set<dirfrag_t> q;
    q.swap(merge_queue);

    for (set<dirfrag_t>::iterator i = q.begin();
	 i != q.end();
	 ++i) {
      CDir *dir = mds->mdcache->get_dirfrag(*i);
      if (!dir ||
	  !dir->is_auth() ||
	  dir->get_frag() == frag_t())  // ok who's the joker?
	continue;

      dout(10) << "do_fragmenting merging " << *dir << dendl;

      CInode *diri = dir->get_inode();

      frag_t fg = dir->get_frag();
      while (fg != frag_t()) {
	frag_t sibfg = fg.get_sibling();
	list<CDir*> sibs;
	bool complete = diri->get_dirfrags_under(sibfg, sibs);
	if (!complete) {
	  dout(10) << "  not all sibs under " << sibfg << " in cache (have " << sibs << ")" << dendl;
	  break;
	}
	bool all = true;
	for (list<CDir*>::iterator p = sibs.begin(); p != sibs.end(); ++p) {
	  CDir *sib = *p;
	  if (!sib->is_auth() || !sib->should_merge()) {
	    all = false;
	    break;
	  }
	}
	if (!all) {
	  dout(10) << "  not all sibs under " << sibfg << " " << sibs << " should_merge" << dendl;
	  break;
	}
	dout(10) << "  all sibs under " << sibfg << " " << sibs << " should merge" << dendl;
	fg = fg.parent();
      }

      if (fg != dir->get_frag())
	mds->mdcache->merge_dir(diri, fg);
    }
  }
}

void MDBalancer::subtree_loads(CInode *in) {
  if (in != NULL) {
    if (in->is_dir()) { 
      list<CDir*> dirfrags;
      in->get_dirfrags(dirfrags);
      for (list<CDir*>::iterator dirfrags_it = dirfrags.begin();
           dirfrags_it != dirfrags.end();
           ++dirfrags_it) {
        CDir *dir = *dirfrags_it;
        string path;
        dir->get_inode()->make_path_string_projected(path);
        // we don't want to look at snap directories
        if (path.find("~") != 0){
          if (dir->pop_auth_subtree.get_meta_total() >= 0.5) {
            if (pop_subtrees.find(path) != pop_subtrees.end())
              pop_subtrees.erase(path);
            pop_subtrees.insert(make_pair(path, dir->pop_auth_subtree));
            for (CDir::map_t::iterator direntry_it = dir->begin();
                 direntry_it != dir->end();
                 ++direntry_it) 
              subtree_loads(direntry_it->second->get_linkage()->get_inode());
          }
        }
      }
    }
  }
}

void MDBalancer::dump_subtree_loads() {
  // print important subtree information  
  set<CDir*> subtrees;
  mds->mdcache->get_fullauth_subtrees(subtrees);
  for (set<CDir*>::iterator it = subtrees.begin();
       it != subtrees.end();
       ++it) {
    CDir *dir = *it;
    pop_subtrees.clear();
    subtree_loads(dir->get_inode());
    size_t count = 0;
    for (map<string,dirfrag_load_vec_t>::iterator it = pop_subtrees.begin();
         it != pop_subtrees.end();
         ++it) {
      pair<string,dirfrag_load_vec_t> p = *it;
      dout(0) << "total=" << p.second.get_meta_total() 
              << " < " << p.second.get(META_POP_IRD).get_last()
              << " " << p.second.get(META_POP_IWR).get_last()
              << " " << p.second.get(META_POP_READDIR).get_last()
              << " " << p.second.get(META_POP_FETCH).get_last()
              << " " << p.second.get(META_POP_STORE).get_last()
              << " > path=" << p.first
              << dendl;
      if (count > (size_t) g_conf->mds_print_nsubtrees) break;
      count++;
    }
  }
}

/* Goal: pass important parameters to Lua so that Lua can make the load balancing decisions
 *  @parm0      char**      debug log
 *  @parm1      int         who I am
 *  @parm2-n    float       meta_load(auth), meta_load(all), req_rate, queue_length, cpu_load_avg
 *  @return     how much load to send to each MDS
 *
 * Parameters (@parm) are passed with the table data structure; values are pushed onto the stack 
 * and "globalized", so that Lua can access them. Return values (@return) are pushed back onto 
 * the stack, so that C++ can access them.
 *
 * The "script" variable has the heuristic, encoded as a Lua script. Eventually, we'd like to 
 * be able to inject this as an argument (injectargs) into the MDS daemon while the process is
 * running, but for now, we just transfer control off to another Lua file.
 */
void MDBalancer::custom_balancer()
{
  const char *log_file = g_conf->log_file.c_str();
  const char *function = "balance";
  int cluster_size = mds->get_mds_map()->get_num_in_mds();
  set<CDir*> subtrees;
  string conf_policies = g_conf->mds_lua_balancer.c_str();
  map<string, string> policies;
  size_t comma, colon;
  string key, value, kvpair;

  dout(0) << "MSEVILLA: balancing policies = " << policies << dendl;

  // Parse the out the policies
  while((comma = conf_policies.find(",")) != string::npos) {
    kvpair = conf_policies.substr(0, comma);
    colon = conf_policies.find(":");
    if (colon == string::npos) {
      dout(0) << "invalid conf: key-value pair (" << kvpair << ") doesn't have a colon (:)" << dendl;
      return;
    }
    policies.insert(pair<string, string>(kvpair.substr(0, colon), kvpair.substr(colon + 1)));
    conf_policies = conf_policies.substr(comma + 1);
  }
  kvpair = conf_policies.substr(0, conf_policies.length());
  colon = conf_policies.find(":");
  if (colon == string::npos) {
   dout(0) << "invalid conf: key-value pair (" << kvpair << ") doesn't have a colon (:)" << dendl;
   return;
  }
  policies.insert(pair<string, string>(kvpair.substr(0, colon), kvpair.substr(colon + 1)));

  // iterate over my subtrees and see if any of them are in the conf
  map<string,string>::iterator policy_it;
  mds->mdcache->get_fullauth_subtrees(subtrees);
  for (set<CDir*>::iterator it = subtrees.begin();
       it != subtrees.end();
       ++it) {
    CDir *dir = *it;
    string path;
    dir->get_inode()->make_path_string_projected(path); 
    dout(0) << "\t determine if any subtrees for auth "<< path << " have a custom balancer" << dendl;  
    if ((policy_it = policies.find(path)) != policies.end()) {
      if (dir->get_balancer() != policy_it->second)
        dir->set_balancer(policy_it->second);
    }
    for (CDir::map_t::iterator i = dir->begin(); 
         i != dir->end();
         ++i) {
      CInode *in = i->second->get_linkage()->get_inode(); 
      if (!in) continue;
      if (!in->is_dir()) continue;

      string dirpath;
      in->make_path_string_projected(dirpath);
      if ((policy_it = policies.find(dirpath)) != policies.end()) {
        list<CDir*> dir_frags;

        dout(0) << "\t\t " << policy_it->first << " has a custom balancer (" << dirpath << "), ship it to MDS " << cluster_size - 1 << dendl;
        in->get_dirfrags(dir_frags);
        for (list<CDir*>::iterator p = dir_frags.begin();
             p != dir_frags.end();
             p++) {
          CDir *subdir = *p;
          if (!subdir->is_auth()) continue;
          if (subdir->is_frozen()) continue;
          if (mds->whoami != cluster_size - 1) {
            dout(0) << "\t\t\t sending dirfrag: " << *subdir << dendl;
            mds->mdcache->migrator->export_dir_nicely(subdir, cluster_size - 1);
          }
          else {
            dout(0) << "\t\t\t not exporting dirfrag: " << *(subdir->get_inode()) << dendl;
          }
        } 
      }
    }
  }
  mds->mdcache->show_subtrees(0);

  // Commence Lua stuff
  lua_State *L = luaL_newstate();
  luaL_openlibs(L);
  lua_newtable(L);

  // attack the subtree with biggest load - this give us the best opportunity to move as much as possible
  set<CDir*> fullauthsubs;
  mds->mdcache->get_fullauth_subtrees(fullauthsubs);
  CDir *max = NULL;
  double max_load = -1;
  for (set<CDir*>::iterator it = fullauthsubs.begin();
       it != fullauthsubs.end();
       ++it) {
    CDir *dir = *it;
    string dirpath;
    double load = 0;
    dir->get_inode()->make_path_string_projected(dirpath);

    if (dirpath.find("~") != string::npos) continue;
    load = dir->pop_auth_subtree.meta_load(rebalance_time, mds->mdcache->decayrate);
    if (load > max_load) {
      max_load = load;
      max = dir;
    }
  }
  if (max_load == -1) 
    dout(0) << "\t there was a problem and I couldn't find the max load" << dendl;
  else
    dout(0) << "\t max load = " << max_load << " for inode: " << *max << dendl;
  dout(0) << "\t using balancer = " << max->get_balancer() << dendl;
  
  if (luaL_loadfile(L, max->get_balancer().c_str()) == 0) {
    if (lua_pcall(L, 0, LUA_MULTRET, 0) == 0) {
      lua_getglobal(L, function);
      if (lua_type(L, lua_gettop(L)) != LUA_TNIL) {
        lua_pushstring(L, log_file);
        lua_pushnumber(L, mds->get_nodeid());
        // rope off the last MDS
        for (int i = 0; i<cluster_size-1; i++) {
          map<int, mds_load_t>::value_type val(i, mds_load_t(ceph_clock_now(g_ceph_context)));
          std::pair < map<int, mds_load_t>:: iterator, bool > r(mds_load.insert(val));
          mds_load_t &load(r.first->second);
          lua_pushnumber(L, load.auth.meta_load());
          lua_pushnumber(L, load.all.meta_load());
          lua_pushnumber(L, load.req_rate);
          lua_pushnumber(L, load.queue_len);
          lua_pushnumber(L, load.cpu_load_avg);
        }
        dout(0) << "[C++] executing " << function << "() in " << max->get_balancer() << dendl;
        if (lua_pcall(L, (cluster_size - 1) * 5 + 2, 1, 0) == 0) {
          // Lua returns a string of loads to send other MDSs
          const char *ret = lua_tostring(L, -1);
          string ret0(ret);
          int i = 0;
          size_t comma;
          lua_pop(L, 1);
          dout(0) << "[C++] received: " << ret0 << dendl;
          while((comma = ret0.find(",")) != string::npos) {
            my_targets[i] = atof(ret0.substr(0, comma).c_str());
            ret0 = ret0.substr(comma + 1);
            i++; 
          }
          my_targets[i] = atof(ret0.substr(0, ret0.length()).c_str());
          for (map<int, double>::iterator i = my_targets.begin();
              i != my_targets.end();
              i++)
            dout(0) << "[C++] \t " << i->first << " = " << i->second << dendl;
        }
      }
      else {
        dout(0) << "[C++] ERROR! couldn't find function named " << function << ": \n\t" << lua_tostring(L, -1) << dendl;
        lua_settop(L, 0);
        return;
      }
    }
    else {
      dout(0) << "[C++] pcall ERROR: " << lua_tostring(L, -1) << dendl;
      lua_settop(L, 0);
      return;
    }
  }
  else {
    dout(0) << "[C++] ERROR! couldn't load file:  \n\t" << lua_tostring(L, -1) << dendl;
    lua_settop(L, 0);
    return;
  }
}


void MDBalancer::force_migrate(CDir *dir, map<string, string> migrations) {
  string path;
  dir->get_inode()->make_path_string_projected(path);
  dout(5) << "determine if auth " << path << " needs to migrate" << dendl;

  // we don't care about snapshot directories
  if (path.find("~") == 0) 
    return;

  map<string,string>::iterator migrations_it;
  if ((migrations_it = migrations.find(path)) != migrations.end()) {
    // the conf file says to migrate the auth subtree
    if (!dir->is_auth() || dir->is_freezing() || dir->is_frozen() ||
        dir->inode->is_base() || dir->inode->is_stray()) return;

    int target = atoi(migrations_it->second.c_str());
    dout(5) << " force migrate auth " << *dir << ", ship it MDS" << target << dendl;
    mds->mdcache->show_subtrees(0);
    mds->mdcache->migrator->export_dir_nicely(dir, target);
    mds->mdcache->show_subtrees(0);
  }
  else {  
    // drill down and see if the conf file tells use to move any of the lower subtrees
    for (CDir::map_t::iterator direntry_it = dir->begin();
         direntry_it != dir->end();
         ++direntry_it) {
      CInode *in = direntry_it->second->get_linkage()->get_inode();
      dout(5) << "  checking direntry: " << *in << dendl;
      if (!in) continue;
      if (!in->is_dir()) continue;
      
      string dirpath;
      in->make_path_string_projected(dirpath);
      if ((migrations_it = migrations.find(dirpath)) != migrations.end()) {
        list<CDir*> dirfrags;
        in->get_dirfrags(dirfrags);
        for (list<CDir*>::iterator dirfrags_it = dirfrags.begin();
             dirfrags_it != dirfrags.end();
             dirfrags_it++) {
          CDir *subdir = *dirfrags_it;
          dout(5) << "   checking dirfrag: " << *subdir << dendl;
          
          if (!subdir->is_auth() || subdir->is_freezing() || subdir->is_frozen() ||
              subdir->inode->is_base() || subdir->inode->is_stray()) continue;

          int target = atoi(migrations_it->second.c_str());
          if (mds->whoami != target) {
            dout(5) << "    force migrate dirfrag: " << *subdir << ", ship it to MDS" << target << dendl;
            mds->mdcache->show_subtrees(0);
            mds->mdcache->migrator->export_dir_nicely(subdir, target);
            mds->mdcache->show_subtrees(0);
          }
          else 
            dout(5) << "    not sending dirfrag (" << *subdir << ") to myself" << dendl;
          force_migrate(subdir, migrations);
        }
      }
    }
  }
}


void MDBalancer::custom_migration() {
    // remove the balancer... for now!
    string migrations_str = g_conf->mds_force_migrate.c_str();
    string kvpair;
    size_t colon, comma;
    map<string, string> migrations;

    // parse out where to send directories
    while ((comma = migrations_str.find(",")) != string::npos) {   
      kvpair = migrations_str.substr(0, comma);
      colon = migrations_str.find(":");
      if (colon == string::npos) {
        dout(0) << "invalid conf: key-value pair (" << kvpair << ") doesn't have a colon (:)" << dendl;
        return;
      }
      migrations.insert(pair<string, string>(kvpair.substr(0, colon), kvpair.substr(colon + 1)));
      migrations_str = migrations_str.substr(comma + 1);
    }
    kvpair = migrations_str.substr(0, migrations_str.length());
    colon = migrations_str.find(":");
    if (colon == string::npos) {
      dout(0) << "invalid conf: key-value pair (" << kvpair << ") doesn't have a colon (:)" << dendl;
      return;
    }
    migrations.insert(pair<string, string>(kvpair.substr(0, colon), kvpair.substr(colon + 1)));

    // do I own any of the dirs?
    set<CDir*> subtrees;
    mds->mdcache->get_fullauth_subtrees(subtrees);
    for (set<CDir*>::iterator it = subtrees.begin();
         it != subtrees.end();
         ++it)
      force_migrate(*it, migrations);
}


void MDBalancer::prep_rebalance(int beat)
{
  dump_subtree_loads();
  if (g_conf->mds_thrash_exports) {
    //we're going to randomly export to all the mds in the cluster
    my_targets.clear();
    set<int> up_mds;
    mds->get_mds_map()->get_up_mds_set(up_mds);
    for (set<int>::iterator i = up_mds.begin();
	 i != up_mds.end();
	 ++i)
      my_targets[*i] = 0.0;
  } else if (g_conf->mds_lua_balancer != "") {
    custom_balancer();
  } else if (g_conf->mds_force_migrate != "") {
    custom_migration();
  }
  try_rebalance();
}



void MDBalancer::try_rebalance()
{
  if (!check_targets())
    return;

  if (g_conf->mds_thrash_exports) {
    dout(5) << "mds_thrash is on; not performing standard rebalance operation!"
	    << dendl;
    return;
  }

  // make a sorted list of my imports
  map<double,CDir*>    import_pop_map;
  multimap<int,CDir*>  import_from_map;
  set<CDir*> fullauthsubs;

  mds->mdcache->get_fullauth_subtrees(fullauthsubs);
  for (set<CDir*>::iterator it = fullauthsubs.begin();
       it != fullauthsubs.end();
       ++it) {
    CDir *im = *it;
    if (im->get_inode()->is_stray()) continue;

    double pop = im->pop_auth_subtree.meta_load(rebalance_time, mds->mdcache->decayrate);
    if (g_conf->mds_bal_idle_threshold > 0 &&
	pop < g_conf->mds_bal_idle_threshold &&
	im->inode != mds->mdcache->get_root() &&
	im->inode->authority().first != mds->get_nodeid()) {
      dout(0) << " exporting idle (" << pop << ") import " << *im
	      << " back to mds." << im->inode->authority().first
	      << dendl;
      mds->mdcache->migrator->export_dir_nicely(im, im->inode->authority().first);
      continue;
    }

    import_pop_map[ pop ] = im;
    int from = im->inode->authority().first;
    dout(15) << "  map: i imported " << *im << " from " << from << dendl;
    import_from_map.insert(pair<int,CDir*>(from, im));
  }



  // do my exports!
  set<CDir*> already_exporting;

  for (map<int,double>::iterator it = my_targets.begin();
       it != my_targets.end();
       ++it) {
    int target = (*it).first;
    double amount = (*it).second;

    if (amount < MIN_OFFLOAD) continue;
    if (amount / target_load < .2) continue;

    dout(5) << "want to send " << amount << " to mds." << target
      //<< " .. " << (*it).second << " * " << load_fac
	    << " -> " << amount
	    << dendl;//" .. fudge is " << fudge << dendl;
    double have = 0;


    show_imports();

    // search imports from target
    if (import_from_map.count(target)) {
      dout(5) << " aha, looking through imports from target mds." << target << dendl;
      pair<multimap<int,CDir*>::iterator, multimap<int,CDir*>::iterator> p =
	import_from_map.equal_range(target);
      while (p.first != p.second) {
	CDir *dir = (*p.first).second;
	dout(5) << "considering " << *dir << " from " << (*p.first).first << dendl;
	multimap<int,CDir*>::iterator plast = p.first++;

	if (dir->inode->is_base() ||
	    dir->inode->is_stray())
	  continue;
	if (dir->is_freezing() || dir->is_frozen()) continue;  // export pbly already in progress
	double pop = dir->pop_auth_subtree.meta_load(rebalance_time, mds->mdcache->decayrate);
	assert(dir->inode->authority().first == target);  // cuz that's how i put it in the map, dummy

	if (pop <= amount-have) {
	  dout(0) << "reexporting " << *dir
		  << " pop " << pop
		  << " back to mds." << target << dendl;
	  mds->mdcache->migrator->export_dir_nicely(dir, target);
	  have += pop;
	  import_from_map.erase(plast);
	  import_pop_map.erase(pop);
	} else {
	  dout(5) << "can't reexport " << *dir << ", too big " << pop << dendl;
	}
	if (amount-have < MIN_OFFLOAD) break;
      }
    }
    if (amount-have < MIN_OFFLOAD) {
      continue;
    }

    // any other imports
    if (false)
      for (map<double,CDir*>::iterator import = import_pop_map.begin();
	   import != import_pop_map.end();
	   import++) {
	CDir *imp = (*import).second;
	if (imp->inode->is_base() ||
	    imp->inode->is_stray())
	  continue;

	double pop = (*import).first;
	if (pop < amount-have || pop < MIN_REEXPORT) {
	  dout(0) << "reexporting " << *imp
		  << " pop " << pop
		  << " back to mds." << imp->inode->authority()
		  << dendl;
	  have += pop;
	  mds->mdcache->migrator->export_dir_nicely(imp, imp->inode->authority().first);
	}
	if (amount-have < MIN_OFFLOAD) break;
      }
    if (amount-have < MIN_OFFLOAD) {
      //fudge = amount-have;
      continue;
    }

    // okay, search for fragments of my workload
    set<CDir*> candidates;
    mds->mdcache->get_fullauth_subtrees(candidates);

    list<CDir*> exports;

    for (set<CDir*>::iterator pot = candidates.begin();
	 pot != candidates.end();
	 ++pot) {
      if ((*pot)->get_inode()->is_stray()) continue;
      find_exports(*pot, amount, exports, have, already_exporting);
      if (have > amount-MIN_OFFLOAD)
	break;
    }
    //fudge = amount - have;

    for (list<CDir*>::iterator it = exports.begin(); it != exports.end(); ++it) {
      dout(0) << "   - exporting "
	       << (*it)->pop_auth_subtree
	       << " "
	       << (*it)->pop_auth_subtree.meta_load(rebalance_time, mds->mdcache->decayrate)
	       << " to mds." << target
	       << " " << **it
	       << dendl;
      mds->mdcache->migrator->export_dir_nicely(*it, target);
    }
  }

  dout(5) << "rebalance done" << dendl;
  show_imports();
}


/* returns true if all my_target MDS are in the MDSMap.
 */
bool MDBalancer::check_targets()
{
  // get MonMap's idea of my_targets
  const set<int32_t>& map_targets = mds->mdsmap->get_mds_info(mds->whoami).export_targets;

  bool send = false;
  bool ok = true;

  // make sure map targets are in the old_prev_targets map
  for (set<int32_t>::iterator p = map_targets.begin(); p != map_targets.end(); ++p) {
    if (old_prev_targets.count(*p) == 0)
      old_prev_targets[*p] = 0;
    if (my_targets.count(*p) == 0)
      old_prev_targets[*p]++;
  }

  // check if the current MonMap has all our targets
  set<int32_t> need_targets;
  for (map<int,double>::iterator i = my_targets.begin();
       i != my_targets.end();
       ++i) {
    need_targets.insert(i->first);
    old_prev_targets[i->first] = 0;

    if (!map_targets.count(i->first)) {
      dout(20) << " target mds." << i->first << " not in map's export_targets" << dendl;
      send = true;
      ok = false;
    }
  }

  set<int32_t> want_targets = need_targets;
  map<int32_t, int>::iterator p = old_prev_targets.begin();
  while (p != old_prev_targets.end()) {
    if (map_targets.count(p->first) == 0 &&
	need_targets.count(p->first) == 0) {
      old_prev_targets.erase(p++);
      continue;
    }
    dout(20) << " target mds." << p->first << " has been non-target for " << p->second << dendl;
    if (p->second < g_conf->mds_bal_target_removal_min)
      want_targets.insert(p->first);
    if (p->second >= g_conf->mds_bal_target_removal_max)
      send = true;
    ++p;
  }

  dout(10) << "check_targets have " << map_targets << " need " << need_targets << " want " << want_targets << dendl;

  if (send) {
    MMDSLoadTargets* m = new MMDSLoadTargets(mds->monc->get_global_id(), want_targets);
    mds->monc->send_mon_message(m);
  }
  return ok;
}

void MDBalancer::find_exports(CDir *dir,
                              double amount,
                              list<CDir*>& exports,
                              double& have,
                              set<CDir*>& already_exporting)
{
  double need = amount - have;
  if (need < amount * g_conf->mds_bal_min_start)
    return;   // good enough!
  double needmax = need * g_conf->mds_bal_need_max;
  double needmin = need * g_conf->mds_bal_need_min;
  double midchunk = need * g_conf->mds_bal_midchunk;
  double minchunk = need * g_conf->mds_bal_minchunk;

  list<CDir*> bigger_rep, bigger_unrep;
  multimap<double, CDir*> smaller;

  double dir_pop = dir->pop_auth_subtree.meta_load(rebalance_time, mds->mdcache->decayrate);
  dout(7) << " find_exports in " << dir_pop << " " << *dir << " need " << need << " (" << needmin << " - " << needmax << ")" << dendl;

  double subdir_sum = 0;
  for (CDir::map_t::iterator it = dir->begin();
       it != dir->end();
       ++it) {
    CInode *in = it->second->get_linkage()->get_inode();
    if (!in) continue;
    if (!in->is_dir()) continue;

    list<CDir*> dfls;
    in->get_dirfrags(dfls);
    for (list<CDir*>::iterator p = dfls.begin();
	 p != dfls.end();
	 ++p) {
      CDir *subdir = *p;
      if (!subdir->is_auth()) continue;
      if (already_exporting.count(subdir)) continue;

      if (subdir->is_frozen()) continue;  // can't export this right now!

      // how popular?
      double pop = subdir->pop_auth_subtree.meta_load(rebalance_time, mds->mdcache->decayrate);
      subdir_sum += pop;
      dout(15) << "   subdir pop " << pop << " " << *subdir << dendl;

      if (pop < minchunk) continue;

      // lucky find?
      if (pop > needmin && pop < needmax) {
	exports.push_back(subdir);
	already_exporting.insert(subdir);
	have += pop;
	return;
      }

      if (pop > need) {
	if (subdir->is_rep())
	  bigger_rep.push_back(subdir);
	else
	  bigger_unrep.push_back(subdir);
      } else
	smaller.insert(pair<double,CDir*>(pop, subdir));
    }
  }
  dout(15) << "   sum " << subdir_sum << " / " << dir_pop << dendl;

  // grab some sufficiently big small items
  multimap<double,CDir*>::reverse_iterator it;
  for (it = smaller.rbegin();
       it != smaller.rend();
       ++it) {

    if ((*it).first < midchunk)
      break;  // try later

    dout(7) << "   taking smaller " << *(*it).second << dendl;

    exports.push_back((*it).second);
    already_exporting.insert((*it).second);
    have += (*it).first;
    if (have > needmin)
      return;
  }

  // apprently not enough; drill deeper into the hierarchy (if non-replicated)
  for (list<CDir*>::iterator it = bigger_unrep.begin();
       it != bigger_unrep.end();
       ++it) {
    dout(15) << "   descending into " << **it << dendl;
    find_exports(*it, amount, exports, have, already_exporting);
    if (have > needmin)
      return;
  }

  // ok fine, use smaller bits
  for (;
       it != smaller.rend();
       ++it) {
    dout(7) << "   taking (much) smaller " << it->first << " " << *(*it).second << dendl;

    exports.push_back((*it).second);
    already_exporting.insert((*it).second);
    have += (*it).first;
    if (have > needmin)
      return;
  }

  // ok fine, drill into replicated dirs
  for (list<CDir*>::iterator it = bigger_rep.begin();
       it != bigger_rep.end();
       ++it) {
    dout(7) << "   descending into replicated " << **it << dendl;
    find_exports(*it, amount, exports, have, already_exporting);
    if (have > needmin)
      return;
  }

}

void MDBalancer::hit_inode(utime_t now, CInode *in, int type, int who)
{
  // hit inode
  in->pop.get(type).hit(now, mds->mdcache->decayrate);

  if (in->get_parent_dn())
    hit_dir(now, in->get_parent_dn()->get_dir(), type, who);
}
/*
  // hit me
  in->popularity[MDS_POP_JUSTME].pop[type].hit(now);
  in->popularity[MDS_POP_NESTED].pop[type].hit(now);
  if (in->is_auth()) {
    in->popularity[MDS_POP_CURDOM].pop[type].hit(now);
    in->popularity[MDS_POP_ANYDOM].pop[type].hit(now);

    dout(20) << "hit_inode " << type << " pop "
	     << in->popularity[MDS_POP_JUSTME].pop[type].get(now) << " me, "
	     << in->popularity[MDS_POP_NESTED].pop[type].get(now) << " nested, "
	     << in->popularity[MDS_POP_CURDOM].pop[type].get(now) << " curdom, "
	     << in->popularity[MDS_POP_CURDOM].pop[type].get(now) << " anydom"
	     << " on " << *in
	     << dendl;
  } else {
    dout(20) << "hit_inode " << type << " pop "
	     << in->popularity[MDS_POP_JUSTME].pop[type].get(now) << " me, "
	     << in->popularity[MDS_POP_NESTED].pop[type].get(now) << " nested, "
      	     << " on " << *in
	     << dendl;
  }

  // hit auth up to import
  CDir *dir = in->get_parent_dir();
  if (dir) hit_dir(now, dir, type);
*/


void MDBalancer::hit_dir(utime_t now, CDir *dir, int type, int who, double amount)
{
  // hit me
  double v = dir->pop_me.get(type).hit(now, amount);

  //if (dir->ino() == inodeno_t(0x10000000000))
  //dout(0) << "hit_dir " << type << " pop " << v << " in " << *dir << dendl;

  // split/merge
  if (g_conf->mds_bal_frag && g_conf->mds_bal_fragment_interval > 0 &&
      !dir->inode->is_base() &&        // not root/base (for now at least)
      dir->is_auth()) {

    dout(20) << "hit_dir " << type << " pop is " << v << ", frag " << dir->get_frag()
	     << " size " << dir->get_frag_size() << dendl;

    // split
    if (g_conf->mds_bal_split_size > 0 &&
	(dir->should_split() ||
	 (v > g_conf->mds_bal_split_rd && type == META_POP_IRD) ||
	 (v > g_conf->mds_bal_split_wr && type == META_POP_IWR)) &&
	split_queue.count(dir->dirfrag()) == 0) {
      dout(10) << "hit_dir " << type << " pop is " << v << ", putting in split_queue: " << *dir << dendl;
      split_queue.insert(dir->dirfrag());
    }

    // merge?
    if (dir->get_frag() != frag_t() && dir->should_merge() &&
	merge_queue.count(dir->dirfrag()) == 0) {
      dout(10) << "hit_dir " << type << " pop is " << v << ", putting in merge_queue: " << *dir << dendl;
      merge_queue.insert(dir->dirfrag());
    }
  }

  // replicate?
  if (type == META_POP_IRD && who >= 0) {
    dir->pop_spread.hit(now, mds->mdcache->decayrate, who);
  }

  double rd_adj = 0;
  if (type == META_POP_IRD &&
      dir->last_popularity_sample < last_sample) {
    float dir_pop = dir->pop_auth_subtree.get(type).get(now, mds->mdcache->decayrate);    // hmm??
    dir->last_popularity_sample = last_sample;
    float pop_sp = dir->pop_spread.get(now, mds->mdcache->decayrate);
    dir_pop += pop_sp * 10;

    //if (dir->ino() == inodeno_t(0x10000000002))
    if (pop_sp > 0) {
      dout(20) << "hit_dir " << type << " pop " << dir_pop << " spread " << pop_sp
	      << " " << dir->pop_spread.last[0]
	      << " " << dir->pop_spread.last[1]
	      << " " << dir->pop_spread.last[2]
	      << " " << dir->pop_spread.last[3]
	      << " in " << *dir << dendl;
    }

    if (dir->is_auth() && !dir->is_ambiguous_auth()) {
      if (!dir->is_rep() &&
	  dir_pop >= g_conf->mds_bal_replicate_threshold) {
	// replicate
	float rdp = dir->pop_me.get(META_POP_IRD).get(now, mds->mdcache->decayrate);
	rd_adj = rdp / mds->get_mds_map()->get_num_in_mds() - rdp;
	rd_adj /= 2.0;  // temper somewhat

	dout(0) << "replicating dir " << *dir << " pop " << dir_pop << " .. rdp " << rdp << " adj " << rd_adj << dendl;

	dir->dir_rep = CDir::REP_ALL;
	mds->mdcache->send_dir_updates(dir, true);

	// fixme this should adjust the whole pop hierarchy
	dir->pop_me.get(META_POP_IRD).adjust(rd_adj);
	dir->pop_auth_subtree.get(META_POP_IRD).adjust(rd_adj);
      }

      if (dir->ino() != 1 &&
	  dir->is_rep() &&
	  dir_pop < g_conf->mds_bal_unreplicate_threshold) {
	// unreplicate
	dout(0) << "unreplicating dir " << *dir << " pop " << dir_pop << dendl;

	dir->dir_rep = CDir::REP_NONE;
	mds->mdcache->send_dir_updates(dir);
      }
    }
  }

  // adjust ancestors
  bool hit_subtree = dir->is_auth();         // current auth subtree (if any)
  bool hit_subtree_nested = dir->is_auth();  // all nested auth subtrees

  while (1) {
    dir->pop_nested.get(type).hit(now, amount);
    if (rd_adj != 0.0)
      dir->pop_nested.get(META_POP_IRD).adjust(now, mds->mdcache->decayrate, rd_adj);

    if (hit_subtree) {
      dir->pop_auth_subtree.get(type).hit(now, amount);
      if (rd_adj != 0.0)
	dir->pop_auth_subtree.get(META_POP_IRD).adjust(now, mds->mdcache->decayrate, rd_adj);
    }

    if (hit_subtree_nested) {
      dir->pop_auth_subtree_nested.get(type).hit(now, mds->mdcache->decayrate, amount);
      if (rd_adj != 0.0)
	dir->pop_auth_subtree_nested.get(META_POP_IRD).adjust(now, mds->mdcache->decayrate, rd_adj);
    }

    if (dir->is_subtree_root())
      hit_subtree = false;                // end of auth domain, stop hitting auth counters.

    if (dir->inode->get_parent_dn() == 0) break;
    dir = dir->inode->get_parent_dn()->get_dir();
  }
}


/*
 * subtract off an exported chunk.
 *  this excludes *dir itself (encode_export_dir should have take care of that)
 *  we _just_ do the parents' nested counters.
 *
 * NOTE: call me _after_ forcing *dir into a subtree root,
 *       but _before_ doing the encode_export_dirs.
 */
void MDBalancer::subtract_export(CDir *dir, utime_t now)
{
  dirfrag_load_vec_t subload = dir->pop_auth_subtree;

  while (true) {
    dir = dir->inode->get_parent_dir();
    if (!dir) break;

    dir->pop_nested.sub(now, mds->mdcache->decayrate, subload);
    dir->pop_auth_subtree_nested.sub(now, mds->mdcache->decayrate, subload);
  }
}


void MDBalancer::add_import(CDir *dir, utime_t now)
{
  dirfrag_load_vec_t subload = dir->pop_auth_subtree;

  while (true) {
    dir = dir->inode->get_parent_dir();
    if (!dir) break;

    dir->pop_nested.add(now, mds->mdcache->decayrate, subload);
    dir->pop_auth_subtree_nested.add(now, mds->mdcache->decayrate, subload);
  }
}






void MDBalancer::show_imports(bool external)
{
  mds->mdcache->show_subtrees();
}
