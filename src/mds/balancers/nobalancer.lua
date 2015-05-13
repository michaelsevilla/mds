require "modules.helpers"
module(..., package.seeall)
function balance (debug, whoami, ...)
  f = io.open(debug, "a")
  io.output(f)

  mdss = modules.helpers.parse_args(...)
  if mdss == -1 then
    io.write("\t[Lua] Failed to parse the loads\n")
    io.close(f)
    return "-1" 
  end

  ret = ""
  for i=1,#mdss do
    ret = ret.."0"
    if i ~= #mdss then ret = ret..", " end
  end 
  io.write("\t[Lua] No balancer doesn't migrate load...\n")
  io.close(f)
  return ret
end

