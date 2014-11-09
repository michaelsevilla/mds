require "modules.parser"
require "modules.helper"
module(..., package.seeall)

FUDGE = 0.001

-- Balancer callbacks
-- - this balancer will evenly split load across MDSs
-- - these balancing decisions are stateless (i.e., no knowledge about 
--   previous function calls is needed for the current decision)
--   - this incurrs extra calculations, but we'll live with that since
--     the number of MDSs is relatively small

-- how load should be calculated
-- input:  @mdss: load maps for each MDS
-- return: scaled load metric
-- Used to determine which MDSs are under/overloaded. This should
-- collapse many metrics into one with some sort of weighted sum
-- that reflects what is important. 
function calculate_load(mdss, who)
  return mdss[who]["all_metaload"] * mdss[who]["cpu_load_avg"]
end

-- when to migrate
-- input:  @mdss: load maps for each MDS
--         @me: the MDS doing this calculation
-- return: 1 if we need to migrate load, 0 otherwise
-- Use a condition or threshold to determine when to migrate load. 
function when(mdss, me)
  total = 0
  for i=1,#loads do total = total + loads[i] end
  io.write(string.format("\t[Lua] \ttarget load = %f\n", total / #mdss))
  if (loads[me + 1] <= FUDGE + target) then return 1
  else return 0
  end
end

-- where to migrate
-- input:  @mdss: load maps for each MDS
-- return: array of importers/exporters
function where(mdss)
  for i=1,#mdss do
    mdss[i]["load"] = total / #mdss - mds[i]["load"]
  end
  io.write(string.format("\t[Lua] Loop to match exporters/importers: 
                          \"+\" means MDS has capacity, 
                          \"-\" means MDS wants to get rid of load\n"))
  print_importers_exporters(relative_loads)
  return relative_loads
end

-- when to migrate
-- input:  @mdss: load maps for each MDS
-- Fill in the MDS "send" fields in the load dictionaries. 
function howmuch(mdss)
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
end

function balance (debug, whoami, ...)
  f = io.open(debug, "a")
  io.output(f)
  mdss = parse_args(...)

  mds_loads(mdss)
  if ~when(mdss, tonumber(whoami)) then
    io.write("\t[Lua] I am not overloaded...\n")
    io.close(f)
    return migrate_none(mdss)
  end
  --where(mdss)
  --howmuch(mdss)

  ret = migrate_string(mdss, tonumber(whoami))
  io.write(string.format("\t[Lua] Return: %s\n", ret)) 
  io.close(f)
  return ret
end

