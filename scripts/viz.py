#!/usr/bin/python
import os, sys, subprocess, time

types = ['MDSs', 'MONs', 'OSDs', 'CLIENTs']

def main():
    print "Let's graph."
    daemons = parse_config()
    print "Who do you want to profile?"
    for t in types: print "-- " + str(types.index(t) + 1) + ". " + t 
    d = raw_input(">> ")
    if d in types:
        graph(d, daemons)
    else:
        try:
            i = int(d)
        except:
            whoops("Your daemon selection sucked (or you just pressed enter). I bequeath an exit upon you.\n")
        if i < len(types):
            graph(types[int(d) - 1], daemons)

def whoops(error):
    print "Whoops. " + error
    sys.exit(0)

def parse_config():
    if len(sys.argv) < 2: config = "/user/msevilla/ceph-deploy/config.sh"
    else: config = sys.argv[1]
    print "- using", config, "and the default directory\n"
    f = open(config, 'r')
    daemons = {}
    for d in types: daemons[d] = None
    for line in f:
        if "#" not in line:
            for d in daemons:
                if d in line:
                    daemons[d] = line.split('=')[1].strip('\n').strip('\"')
    for d in daemons:
        if daemons[d] is None:
            f.close()
            whoops("Failed to find all daemons in the config.\n")
    f.close()
    return daemons

def run(command):
    p = subprocess.Popen(command.split(), stdout=subprocess.PIPE)
    output = p.communicate()[0]
    if p.returncode != 0:
        whoops("Failed to run command: " + command)
    return output

def graph(d, daemons):
    ds = daemons.get(d).split()

    tool = raw_input("Pick metric type \n-- 1. utilization\n-- 2. perfcounter \n>> ")
    print "tool", tool, "\n"
    if tool == 'utilization' or tool == '1':
        files = run("ls ./cpu")
        for f in files.split():
            if "issdm-" in f and ds[0] in f and "tab" in f:
                filename = "./cpu/" + f
        options = run("parse_collectl.py " + filename)
    elif tool == 'perfcounter' or tool == '2':
        options = run("parse_perf.py ./perf/" + ds[0] + "-0 component component")
        component = raw_input("Pick component: " + str(options) + ">> ")
        if component not in options:
            print "Sorry, not one of the components\n"
            graph(daemons)
        print "\n"
        filename = "./perf/" + component + "-issdm-" + ds[0] + ".timing"
        options = run("parse_perf.py ./perf/" + ds[0] + "-0 " + component + " legend")
 
    else:
        print "Sorry, I don't know that tool.\n"
        graph(daemons)

    vals = raw_input("Pick value to graph: " + str(options) + "\n>> ")
    if not vals:
        print "Sorry, you didn't tell me what to plot.\n"
        graph(daemons)
    fields = vals.split()
    indices = []
    f = ""
    for v in fields:
        if v not in options:
            print "Sorry, not one of the plottable values.\n"
            graph(daemons)
        indices.append(options.split().index(v) + 1)
        f += v + ","
    print "\n"

    s = ""
    for i in indices:
        s += str(i) + ","
    s = s[0:len(s) - 1]
    f = f[0:len(f) - 1]
    for mds in ds:
        if tool == 'utilization' or tool == '1':
            cmd = "tailplot -x 2 --field-format=2,date,HH:mm:ss --x-format=date,HH:mm:ss -f " + f + " -s " + s + " " + filename
        elif tool == 'perfcounter' or tool == '2':
            cmd = "tailplot -x 2 --field-format=2,date,HH:mm:ss --x-format=date,HH:mm:ss -f " + f + " -s " + s + " " + filename
        print "Running:", cmd
        subprocess.Popen(cmd.split())
        time.sleep(3)
    print "********** DONE **********\n\n"
    main()
    
main()
