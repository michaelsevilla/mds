#include <iostream>
#include <fstream>
#include <string>
#include <cstring>
#include <stdlib.h>

extern "C" {
    #include "lua.h"
    #include "lualib.h"
    #include "lauxlib.h"
}

int main(int argc, char ** argv) {
  std::cout << "Testing importing Lua modules in scripts.\n";  
  //const char *when = 
  const char *x;
  std::string preamble = 
    "package.path = package.path .. \"/tmp/balancers/modules/helpers.lua\"\n"
    "require \"helpers\"\n"
    "io.write(\"\t[Lua5.2] version - \", _VERSION, \"!\\n\")\n";
  std::string when = 
    "mdss = helpers.parse_args(1, 2, 4, 5, 6, 7, 1, 2, 4, 5, 6, 7)\n"
    "io.write(string.format(\"\t[Lua5.2] found %s MDS(s)!\\n\", #mdss))\n"
    "return \"0, 0, 0\"\n"; 
  std::string script = preamble + when;
  x = script.c_str();
  //std::cout << "script: " << x;

  lua_State *L = luaL_newstate();
  luaL_openlibs(L);
  lua_newtable(L);
  if (luaL_dostring(L, x) > 0)
    lua_error(L);
}
