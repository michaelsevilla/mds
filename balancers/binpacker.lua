-- Send off the fragments with the most load, first
function send_until_target(debug, target, dirfrags)
  sum = 0
  send = ""
  mds1 = {}
  for i=1,#dirfrags do
    sum = sum + dirfrags[i]
    if sum <= target then table.insert(mds1, i)
    else sum = sum - dirfrags[i] end
  end
  mds1_sum = 0
  for i=1,#mds1 do mds1_sum = mds1_sum + dirfrags[mds1[i]] end
  return math.abs(mds1_sum-target), mds1
end

function small_first(debug, target, dirfrags)
  d = 9
  s = {1, 2}
  --table.sort(dirfrags)
  --d, s = send_until_target(debug, target, dirfrags)
  return d, s
end

function big_first(debug, target, dirfrags)
--  table.sort(dirfrags, function(a,b) return a>b end)
--  d, s = send_until_target(debug, target, dirfrags)
--  for i=1,#s do s[i] = (#dirfrags + 1) - s[i] end
--  return d, s
  x = {1, 2, 3, 4, 5}
  return 3, x
end
function big_first_plus1(debug, target, dirfrags)
  -- want to add the next smallest one, since we are up against the barrier
  -- if we hadn't added it already, then we didn't go all the way to the threshold
end

-- input:  @target:   STRING how much load we went to offload
--         @dirfrags: STRING the loads for the directory fragments
strategies = {big_first, small_first}
function pack(debug, target, ...)
  f = io.open(debug, "w")
  io.output(f)
  io.write(string.format("  [Lua5.2] using %d binpacking strategies to figure out how to send load=%f.\n", 
          #strategies, target))

  dirfrags = ipairs{...}
  --for k,v in ipairs{...} do table.insert(dirfrags, v) end
  --io.write("  [Lua5.2] print dirfrags: ")
  --for i=1,#dirfrags do io.write(string.format(" %f", dirfrags[i])) end
  io.write("\n")

  distance = 2147483648
  export = ""
  function dofunction(f) return f(debug, target, dirfrags) end
  for i=1,#strategies do 
    d, e = dofunction(strategies[i]) 
    table.sort(e)
    io.write(string.format("  [Lua5.2]  strategy %d: distance=%f, export_dirfrags=", 
             i, d))
    for j=1,#e do io.write(string.format(" %d", e[j])) end
    io.write("\n")
    if d < distance then
      distance = d
      export = e
    end
  end

  io.close(f)
  return export
end



