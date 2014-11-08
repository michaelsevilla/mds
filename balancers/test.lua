require "modules.parser"

io.write(string.format("Test program for launching MDS Lua5.2 functions\n"))
mdss = modules.parser.parse_args(6, 0, 3, 4, 1, 7)
io.write(string.format("Found %d MDS(s):\n", #mdss))
for i=1, #mdss do
    io.write(string.format("MDS%d", i))
    for k,v in pairs(mdss[i]) do io.write(string.format(" %s=%s ", k, v)) end
    io.write("\n")
end


