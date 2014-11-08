require "modules.parser"
require "nobalancer"
require('luaunit')

function test_parser()
    mdss = modules.parser.parse_args(6, 0, 3, 4, 1, 7)
    assertEquals(#mdss, 1)
    assertNotEquals(#mdss, 2)
    assertNotEquals(mdss, -1)

    mdss = modules.parser.parse_args(6, 0, 3, 4, 1, 7, 8)
    assert(type(mdss), 'number')
    assertEquals(mdss, -1)
end

--  ret = nobalancer.balance("./out", 0, 1, 2, 3, 4, 5, 6)
lu = LuaUnit.new()
lu:setOutputType("tap")
os.exit( lu:runSuite() )
