FUDGE = 0.001
METRICS = {"auth", "all", "req", "q", "cpu", "mem"}
module(..., package.seeall)

-- name:   print_metrics
-- input:  debug log name, MDSs[] metric measurements
-- Print out the metric measurements for each MDS.
function print_metrics(debug, mdss)
  f = io.open(debug, "a")
  io.output(f)
  io.write("  [Lua5.2] load vector: <")
  for i=1, #METRICS do io.write(string.format(" %s ", METRICS[i])) end
  io.write(">\n")
  for i=1, #mdss do
    io.write(string.format("  [Lua5.2]   MDS%d: load=%f <", i - 1, mdss[i]["load"]))
    for j=1, #METRICS do
      io.write(string.format(" %f", mdss[i][METRICS[j]]))
    end
    io.write(" >\n")
  end
  io.close(f)
end

-- name:   parse_args
-- input:  debug log name, me, 6-tuples for each MDS
--         (metadata load on authority, metadata on all other subtrees, 
--          request rate, queue length, CPU load, memory load)
-- return: array mapping MDSs to load maps
-- Parse the arguments passed from C++ Ceph code. 
function parse_args(arg)
  debug = arg[1]
  whoami = arg[2]
  myauth = arg[3]
  metrics = {}
  if (#arg - 3) % #METRICS ~= 0 then
    f = io.open(debug, "a")
    io.output(f)
    io.write("  [Lua5.2] Didn't receive all load metrics for all MDSs\n")
    io.close(f)
    return -1
  end
  i = 1
  for k,v in ipairs(arg) do 
    if k > 3 then  
      metrics[i] = v 
      i = i + 1
    end 
  end
  mdss = {}
  nmds = 0
  for i=0, #metrics-1 do
    if i % #METRICS == 0 then 
      nmds = nmds + 1
      mdss[nmds] = {}
      mdss[nmds]["load"] = 0
    end
    mdss[nmds][METRICS[(i % #METRICS) + 1]] = metrics[i+1]
    i = i + 1
  end
  return whoami, mdss, myauth
end


