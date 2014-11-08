FUDGE = 0.001

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

