require "modules.parser"
module(..., package.seeall)
function balance (debug, whoami, ...)
  f = io.open(debug, "a")
  io.output(f)
  mdss = modules.parser.parse_args(...)
  ret = ""
  for i=1,#mdss do
    ret = ret.."0"
    if i ~= #mdss then ret = ret..", " end
  end 
  io.write("\t[Lua] No balancer doesn't migrate load...\n")
  io.close(f)
  return ret
end

