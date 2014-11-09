require "modules.parser"
require "nobalancer"
require('luaunit')

function test_parser()
  f = io.open("./out", "a")
  io.output(f)
  mdss = modules.parser.parse_args(6, 0, 3, 4, 1, 7)
  assertNotEquals(#mdss, 2)

  mdss = modules.parser.parse_args(6, 0, 3, 4, 1, 4,
                                   3, 1, 3, 5, 6, 4,
                                   2, 3, 1, 3, 4, 9)
  assertEquals(#mdss, 3)

  mdss = modules.parser.parse_args(6, 0, 3, 4, 1, 7, 8)
  assert(type(mdss), 'number')
  assertEquals(mdss, -1)


  mdss = modules.parser.parse_args(6, 0, 3, 4, 1, 4,
                                   3, 1, 3, 5, 6,
                                   2, 3, 1, 3, 4, 9)
  assert(type(mdss), 'number')
  assertEquals(mdss, -1)
  io.close(f)
end

function test_nobalancer()
  ret = nobalancer.balance("./out", 0, 1, 2, 3, 4, 5, 6)
  assertEquals(ret, "0") 

  ret = nobalancer.balance("./out", 0, 
                            1, 2, 3, 4, 5, 6, 
                            1, 2, 3, 4, 5, 6,
                            1, 2, 3, 4, 5, 6)
  assertEquals(ret, "0, 0, 0") 

  ret = nobalancer.balance("./out", 0, 1, 2, 3, 4, 5, 6, 7)
  assertEquals(ret, "-1")
end

lu = LuaUnit.new()
lu:setOutputType("tap")
os.exit( lu:runSuite() )
