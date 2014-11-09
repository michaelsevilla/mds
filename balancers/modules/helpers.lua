FUDGE = 0.001
ARGS = {"auth_metaload", "all_metaload", "req_rate", "queue_len", "cpu_load_avg", "mem_load"}

-- Modules that help expose the balancer APIs
module(..., package.seeall)
require "nobalancer"
require "balancer"

-- name:   parse_args
-- input:  6-tuples for each MDS
--         (metadata load on authority, metadata on all other subtrees, 
--          request rate, queue length, CPU load, memory load)
-- return: array mapping MDSs to load maps
-- Parse the arguments passed from C++ Ceph code. These tuples need
-- to be standarized in the "balancer API".
function parse_args(...)
  if #{...} % #ARGS ~= 0 then
    io.write(string.format("\t[Lua] Didn't receive all load metrics for all MDSs"))
    return -1
  end
  mdss = {}
  i = 0
  nmds = 0
  for k,v in ipairs{...} do 
    if i % #ARGS == 0 then 
      nmds = nmds + 1
      mdss[nmds] = {}
    end
    mdss[nmds][ARGS[(i % #ARGS) + 1]] = v
    i = i + 1
  end

  for i=1,#mdss do
    mdss[i]["load"] = 0
    mdss[i]["send"] = {}
    for j=1,#mdss do mdss[i]["send"][j] = 0 end
  end
  return mdss
end

function print_importers_exporters(relative_loads)
  io.write(string.format("\t[Lua] \t"))
  for i=1,#relative_loads do
    if i == #relative_loads then
      io.write(string.format("MDS%d=%f\n", i - 1, relative_loads[i]))
    else
      io.write(string.format("MDS%d=%f, ", i - 1, relative_loads[i]))
    end
  end
end

function max_importer_exporter(relative_loads)
  max = 0
  min = 0
  whoim = 0
  whoex = 0
  for i=1,#relative_loads do
    l = relative_loads[i]
    if l > max then
      max = l
      whoim = i
    end
    if l < min then
      min = l
      whoex = i
    end
  end
  return whoim, whoex
end

function keep_balancing(relative_loads)
  -- stop balancing if no one has capacity
  importers = 0
  for i=1,#relative_loads do
    if relative_loads[i] > FUDGE then
      importers = importers + 1
    end
  end

  -- keep balancing if someone has too much load
  if importers > 0 then
    for i=1,#relative_loads do
      if relative_loads[i] < -FUDGE then
        return 1
      end
    end
  end
  return 0
end

-- get all load for all MDSs
-- input:  @mdss: load maps for each MDS
-- Helper function that calculates the load for each MDS and stores
-- it with the MDS load dictionaries.
function mds_loads(mdss)
  for i=1,#mdss do
    l = calculate_load(mdss, i)
    mdss[i]["load"] = l 
  end 
end

-- return a string indicating no migrations
-- input:  @mdss: load maps for each MDS
-- return: "0, 0, ..., 0" string
-- Helper function that constructs a no migration string to return
-- to Ceph (i.e. this string will not incurr any migrations). 
function migrate_none_string(mdss)
  ret = ""
  for i=1,#mdss do 
    ret = ret.."0"
    if i ~= #mdss then ret = ret..", " end
  return ret
  end
end

-- return a string indicating where to migrate strings
-- input:  @mdss: load maps for each MDS
-- return: string saying where to send load
-- Helper function that constructs the migration string to return
-- to Ceph. It iterates over the send array in each MDS load 
-- dictionary and constructs the proper string.
function migrate_string(mdss, me)
  ret = ""
  for i=1,#mdss[1]["send"] do
      ret = ret..mdss[me + 1]["send"][i]
    if i ~= #mdss[me + 1]["send"] then
      ret = ret..", "
    end
  end 
end
 
