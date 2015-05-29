function when(MDSs, whoami)
  if MDSs[whoami] > 0 then return true 
  else return false end
end 
-- scalable spill evenly
where_string = "\
my_map = {} -- key = MDSs, value = table of load tranfers \
for j=1,#MDSs do my_map[j] = {} end \
-- construct state for other MDSs \
for i=1,#MDSs do \
  migrated = false \
  t = i \
  while migrated == false do \
    t = t+1 \
    if t > #MDSs then t = 1 end \
    if t == i then break end \
    if MDSs[t] < 1 then \
      go = true \
      -- make sure no one else is going to hit your target \
      for j=1,#MDSs do \
        for target,send_load in pairs(my_map[j]) do \
          if target == t and i > j then go = false end \
        end \
      end \
      if go==true then \
        my_map[i][t] = MDSs[i]/2 \
        migrated = true \
      end \
    end \
  end \
end \
for j=1,#MDSs do \
  if j == whoami then \
    for target, send_load in pairs(my_map[j]) do \
      targets[target] = send_load \
    end \
  end \
end"

-- unscalable spill evenly
where_naive_string =  "\
my_map = {} -- key = MDSs, value = table of load tranfers \
--for j=1,#MDSs do my_map[j] = {} end \
--  t = ((#MDSs-whoami+1)/2)+whoami \
--  if t>#MDSs then t = whoami end \
--  while t~=whoami and MDSs[t]>0.01 do t=t-1 end \
--  if t~=whoami and MDSs[whoami]>0.01 and MDSs[t]<0.01 then \
--    load_transfer_map[whoami][t] = MDSs[whoami]/2 \
--  end \
--end"


where = loadstring(where_string) 
print(where_string)
nMDSs = arg[1]
MDSs = {}               -- state of the cluster before the migration
history = {}            -- history of MDSs[]
load_transfer_map = {}  -- key = MDSs, value = table of load tranfers

-- initialize the cluster and start the simulator
for i=1,nMDSs do MDSs[i] = 0 end
MDSs[1] = 100
history[0] = {}
for j=1,#MDSs do history[0][j] = MDSs[j] end

io.write("\n\n####################\n# MIGRATIONS       # \n####################\n")
whoami = -1
for i=1,10 do
  for l=1,#MDSs do
    targets = {}
    whoami = l
    for j=1, #MDSs do targets[j] = 0 end
    if when(MDSs, whoami) == true then
      where()
      load_transfer_map[whoami] = {}
      for send_target,send_load in pairs(targets) do
        load_transfer_map[whoami][send_target] = send_load
      end
    end
  end

  -- transfer the loads
  io.write(string.format("iteration %d: ", i))
  for j,target_pair in pairs(load_transfer_map) do
    for target, send_load in pairs(target_pair) do
      if send_load > 0 then
        io.write(string.format("MDS%d->MDS%d(%d), ", j, target, send_load))
        MDSs[target] = MDSs[target] + send_load
        MDSs[j] = MDSs[j] - send_load
      end
    end
  end
  io.write(string.format("\n"))

  -- keep a running history
  history[i] = {}
  for k=1,#MDSs do
    history[i][k] = MDSs[k]
  end
end

-- print out the history
io.write("\n\n####################\n# LOADS            # \n####################\n")
io.write("           \t ")
for i=1,#MDSs do io.write(string.format("MDS%d\t", i)) end
io.write("\n")
for i=0,#history do
  done = true
  io.write(string.format("iteration %d:\t[", i))
  for j=1,#history[i] do
    if history[i][j] ~= 0 then io.write(string.format(" %d%%\t", history[i][j]))
    else io.write(string.format(" --\t")) end
    if history[i][j] ~= history[i][1] then done = false end
    if j % 32 == 0 and #history[i] > 32 then io.write("\n           \t ") end
  end
  io.write("]\n")

  -- break if they are all the same...
  if done == true then break end
end
