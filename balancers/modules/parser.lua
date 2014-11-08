FUDGE = 0.001
ARGS = {"auth_metaload", "all_metaload", "req_rate", "queue_len", "cpu_load_avg", "mem_load"}

-- Modules that help expose the balancer APIs
module(..., package.seeall)

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

function balance (debug, whoami, ...)
  f = io.open(debug, "a")
  io.output(f)
  mdss = parse_args(...)
  me = tonumber(whoami)

  -- load: used to determine which MDSs are under/overloaded
  loads = {}
  total = 0
  for i=1,#mdss do
    l = mdss[i]["all_metaload"] * mdss[i]["cpu_load_avg"]
    total = total + l
    table.insert(loads, l)
  end
  target = total / #mdss
  io.write(string.format("\t[Lua] \ttarget load = %f\n", target))

  -- when to migrate
  if (loads[me + 1] <= FUDGE + target) then
    io.write("\t[Lua] I am not overloaded...\n")
    io.close(f)
    return "0, 0, 0"
  end

  -- where to migrate
  relative_loads = {}
  for i=1,#mdss do
    table.insert(relative_loads, target - loads[i])
  end
  io.write(string.format("\t[Lua] Loop to match exporters/importers: \"+\" means MDS has capacity, \"-\" means MDS wants to get rid of load\n"))
  print_importers_exporters(relative_loads)

  -- how much to migrate
  while keep_balancing(relative_loads) == 1 do
    whoim, whoex = max_importer_exporter(relative_loads)
    importer_capacity = relative_loads[whoim]
    exporter_excess = math.abs(relative_loads[whoex])
    amount = 0
    if importer_capacity > exporter_excess then
      amount = exporter_excess
    else
      amount = importer_capacity
    end
    io.write(string.format("\t[Lua] \t\tsend %f load (MDS%d -> MDS%d)\n", amount, whoex - 1, whoim - 1))
    mdss[whoex]["send"][whoim] = amount
    relative_loads[whoex] = relative_loads[whoex] + amount
    relative_loads[whoim] = relative_loads[whoim] - amount
    print_importers_exporters(relative_loads)
  end
  ret = ""
  for i=1,#mdss[1]["send"] do
      ret = ret..mdss[me + 1]["send"][i]
    if i ~= #mdss[me + 1]["send"] then
      ret = ret..", "
    end
  end 
  io.write(string.format("\t[Lua] Return: %s\n", ret)) 
  io.close(f)
  return ret
end

