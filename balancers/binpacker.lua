-- Send off the fragments with the most load, first
function send_until_target(debug, target, dirfrags)
  sum = 0
  send_dfs = {}
  nextmin = {-1, 2147483648}
  for i=1,#dirfrags do
    sum = sum + dirfrags[i][2]
    if sum <= target then table.insert(send_dfs, dirfrags[i])
    else 
      sum = sum - dirfrags[i][2] 
      if dirfrags[i][2] < nextmin[2] then nextmin = dirfrags[i] end
    end
  end
  return send_dfs, nextmin
end

function small_first(debug, target, dirfrags)
  table.sort(dirfrags, function(a,b) return a[2] < b[2] end )
  s, n = send_until_target(debug, target, dirfrags)
  return s
end
function small_first_plus1(debug, target, dirfrags)
  table.sort(dirfrags, function(a,b) return a[2] < b[2] end )
  s, n = send_until_target(debug, target, dirfrags)
  table.insert(s, n)
  return s
end

function big_first(debug, target, dirfrags)
  table.sort(dirfrags, function(a,b) return a[2] > b[2] end )
  s, n = send_until_target(debug, target, dirfrags)
  return s
end
function big_first_plus1(debug, target, dirfrags)
  -- want to add the next smallest one, since we are up against the barrier
  -- if we hadn't added it already, then we didn't go all the way to the threshold
  table.sort(dirfrags, function(a,b) return a[2] > b[2] end )
  s, n = send_until_target(debug, target, dirfrags)
  table.insert(s, n)
  return s
end

-- input:  @target:   STRING how much load we went to offload
--         @dirfrags: STRING the loads for the directory fragments
strategies = {small_first, big_first, small_first_plus1, big_first_plus1}
function pack(debug, target, ...)
  f = io.open(debug, "w")
  io.output(f)
  io.write(string.format("  [Lua5.2] using %d binpacking strategies, trying to send load=%f.\n", 
          #strategies, target))

  dirfrags = {}
  io.write("  [Lua5.2] print dirfrags: ")
  for k,v in ipairs{...} do 
    dirfrags[k] = {k, v}
    io.write(string.format(" df[%d]=%f", dirfrags[k][1], dirfrags[k][2]))
  end
  io.write("\n")


  distance = 2147483648
  send = {}
  function dofunction(f) return f(debug, target, dirfrags) end
  for i=1,#strategies do 
    s = dofunction(strategies[i]) 

    sum = 0
    for i=1,#s do sum = sum + s[i][2] end
    d = math.abs(sum-target)
    io.write(string.format("  [Lua5.2]  strategy %d: distance=%f, export_dirfrags=", 
             i, d))
    for k,v in ipairs(s) do io.write(string.format(" %d", v[1])) end
    io.write("\n")
    if d < distance then
      distance = d
      send = s
    end
  end

  ret = ""
  for k,v in ipairs(send) do ret = ret.." "..v[1] end

  io.close(f)
  return ret
end



