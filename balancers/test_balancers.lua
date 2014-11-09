require "modules.helpers"
require "nobalancer"
require('luaunit')

-- Test modules/helpers.lua
function test_parse_args()
  f = io.open("/tmp/out", "a")
  io.output(f)
  mdss = modules.helpers.parse_args(6, 0, 3, 4, 1, 7)
  assertNotEquals(#mdss, 2)

  mdss = modules.helpers.parse_args(6, 0, 3, 4, 1, 4,
                                    3, 1, 3, 5, 6, 4,
                                    2, 3, 1, 3, 4, 9)
  assertEquals(#mdss, 3)

  mdss = modules.helpers.parse_args(6, 0, 3, 4, 1, 7, 8)
  assert(type(mdss), 'number')
  assertEquals(mdss, -1)


  mdss = modules.helpers.parse_args(6, 0, 3, 4, 1, 4,
                                    3, 1, 3, 5, 6,
                                    2, 3, 1, 3, 4, 9)
  assert(type(mdss), 'number')
  assertEquals(mdss, -1)
  io.close(f)
end

function test_mds_loads()
  mdss = modules.helpers.parse_args(6, 0, 3, 4, 1, 4,
                                    3, 1, 3, 5, 6, 4,
                                    2, 3, 1, 3, 4, 9)
  modules.helpers.mds_loads(mdss)   
  
end



-- Test nobalancer.lua
function test_nobalancer()
  ret = nobalancer.balance("/tmp/out", 0, 1, 2, 3, 4, 5, 6)
  assertEquals(ret, "0") 

  ret = nobalancer.balance("/tmp/out", 0, 
                            1, 2, 3, 4, 5, 6, 
                            1, 2, 3, 4, 5, 6,
                            1, 2, 3, 4, 5, 6)
  assertEquals(ret, "0, 0, 0") 


  ret = nobalancer.balance("/tmp/out", 0, 
                            1, 2, 3, 4, 5, 6, 
                            1, 2, 3, 4, 5, 6,
                            1, 2, 3, 4, 5, 6, 
                            1, 2, 3, 4, 5, 6,
                            1, 2, 3, 4, 5, 6)
  assertEquals(ret, "0, 0, 0, 0, 0") 

  ret = nobalancer.balance("/tmp/out", 0, 1, 2, 3, 4, 5, 6, 7)
  assertEquals(ret, "-1")

  ret = nobalancer.balance("/tmp/out", 0, 
                            1, 2, 3, 4, 5, 6, 
                            1, 2, 3, 4, 5, 6,
                            1, 2, 3, 4, 5, 6, 8,
                            1, 2, 3, 4, 5, 6,
                            1, 2, 3, 4, 5, 6)
  assertEquals(ret, "-1")
end

--function test_balancer_calculate_load()
--  mdss = modules.helpers.parse_args(6, 0, 3, 4, 1, 4,
--                                   3, 1, 3, 5, 6, 4,
--                                   2, 3, 1, 3, 4, 9)
--  assertEquals(#mdss, 3)
--end


lu = LuaUnit.new()
lu:setOutputType("tap")
os.exit( lu:runSuite() )
