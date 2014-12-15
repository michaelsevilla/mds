#!/usr/bin/python
import os, sys, subprocess, time

types = ['MDSs', 'MONs', 'OSDs', 'CLIENTs']

def whoops(error):
    print "Whoops. " + error
    sys.exit(0)

def retry_graph(d, error):
    print "Sorry. " + error + "\nLet's try again!\n"
    graph(d)

def retry_main(error):
    print "Sorry. " + error + "\nLet's try again!\n"
    main()

def raw_input_exit(msg):
    ret = raw_input(msg + ">> ")
    if ret == 'exit':
        print "Ok, bye!"
        sys.exit(0)
    print "\n"
    return ret

# run a generic command with bash
def run(command):
    p = subprocess.Popen(command.split(), stdout=subprocess.PIPE)
    output = p.communicate()[0]
    if p.returncode != 0: 
        whoops("Failed to run command: " + command)
    return output

# pull out the server IDs from the config file
def parse_config():
    if len(sys.argv) < 2: 
        config = "/user/msevilla/ceph-deploy/config.sh"
    else: 
        config = sys.argv[1]

    try:
        f = open(config, 'r')
    except IOError:
        whoops("Can't find the config file: " + config)
    daemons = {}
    for d in types: 
        daemons[d] = None
    for line in f:
        if "#" not in line:
            for d in daemons:
                if d in line:
                    daemons[d] = line.split('=')[1].strip('\n').strip('\"')
    f.close()
    # make sure we have all server types
    for d in daemons:
        if daemons[d] is None:
            whoops("Failed to find all daemons in the config.\n")
    return daemons

# read the config and print out which daemons are on which servers
def config(d):
    daemons = parse_config()
    print d + ": ",
    for daemon in daemons.get(d).split():
        print daemon, 
    print "\n"
    main()

# check if the value (either given as a string OR int) is in the array of types
def get_name(val, array):
    ret = val
    if val not in array:
        # maybe the user entered the number instead
        try:
            ret = array[int(val) - 1]
        except:
            return -1
    return ret

# array version of the above function
def get_names(vals, array):
    ret = []
    for v in vals:
        # this will append a -1 if it fails
        ret.append(get_name(v, array))
    return ret

# use tailplot to graph the user-selected component and values
def graph(d):
    # check that the directory has all the necessary folders
    dirs = os.listdir("./")
    if 'perf' not in dirs and 'cpu' not in dirs:
        whoops("It looks like you aren't in a directory that has the necessary log files (e.g., ./perf, ./cpu).")

    daemons = parse_config().get(d).split()
    metric = raw_input_exit("Pick metric type \n-- 1. utilization\n-- 2. perfcounter\n-- 3. performance\n")
    
    # each metric has unique 1. file names and 2. options for graphing
    if metric == 'utilization' or metric == '1':
        # pull out the file name
        files = os.listdir("./cpu")
        for f in files:
            if "issdm-" in f and daemons[0] in f and "tab" in f:
                filename = "./cpu/" + f
        # pull out the values we can graph
        options = run("parse_collectl.py " + filename)
    elif metric == 'perfcounter' or metric == '2':
        # pull out the component in the perf counter file
        options = run("parse_perf.py ./perf/" + daemons[0] + "-0 component component")
        component = raw_input_exit("Pick component: " + str(options) + "\n")
        if component not in options:
            retry_graph(d, "I don't know that metric.")
        filename = "./perf/" + component + "-issdm-" + daemons[0] + ".timing"
        # pull out the values we can graph
        options = run("parse_perf.py ./perf/" + daemons[0] + "-0 " + component + " legend")
    elif metric == 'performance' or metric == '3':
        options = "date time latency thruput"
    else:
        retry_graph(d, "I don't know that metric.")
    
    print "Pick a value to graph:"
    splitoptions = options.split() 
    for i in range(0, len(splitoptions)): print str(i + 1) + "." + splitoptions[i] + " ",
    vals = raw_input_exit("\n")
    if not vals:
        retry_graph(d, "You didn't tell me what to plot.")
    fields = get_names(vals.split(), splitoptions)
    if -1 in fields:
        retry_graph(d, "Couldn't find all the values (" + str(fields) + ") in the options")
    if 'date' in fields or 'time' in fields:
        retry_graph(d, "It doesn't make sense to plot date/time on the y axis.")
    indices = []
    f = ""
    for v in fields:
        if v not in options.split():
            retry_graph(d, "That isn't one of the plottable values.")
        indices.append(options.split().index(v) + 1)
        f += v + ","

    s = ""
    for i in indices:
        s += str(i) + ","
    s = s[0:len(s) - 1]
    f = f[0:len(f) - 1]

    for daemon in daemons:
        if metric == 'utilization' or metric == '1':
            # pull out the file name
            files = os.listdir("./cpu")
            for name in files:
                if "issdm-" in name and daemon in name and "tab" in name:
                    filename = "./cpu/" + name
        elif metric == 'perfcounter' or metric == '2':
            filename = "./perf/" + component + "-issdm-" + daemon + ".timing"
        elif metric == 'performance' or metric == '3':
            filename = "./perf/replyc_issdm-" + daemon 
        if os.path.exists(filename):
            cmd = "tailplot -x 2 --field-format=2,date,HH:mm:ss --x-format=date,HH:mm:ss -f " + f + " -s " + s + " -t issdm-" + daemon + " " + filename
        else:
            whoops("Filename " + filename + " does not exists. You might have to make it manually You might have to make it manually.")
        print "Running:", cmd
        subprocess.Popen(cmd.split())
    print "********** DONE **********\n\n"
    time.sleep(3)
    main()
    
def main():
    action = raw_input_exit("What do you want to do (enter 'exit' at any time...)?\n-- 1. view config\n-- 2. graph\n")
    if not action or action not in ['view config', 'graph', '1', '2']:
        retry_main("Please select from the action list.")
    print "Who do you want to see?"
    for t in types: print "-- " + str(types.index(t) + 1) + ". " + t

    d = get_name(raw_input_exit(""), types)
    if d == -1:
        retry_main("Your daemon selection sucked (or you just pressed enter).\n")

    if action == 'view config' or action == '1':
        config(d)
    elif action == 'graph' or action == '2': 
        graph(d)

main()
