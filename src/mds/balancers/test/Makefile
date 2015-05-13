all : run
#fxn_lua

run : embed.cpp
	g++ embed.cpp -o run -I/usr/include/lua5.2/ -llua5.2 -Wall

#embed_lua : embed_lua.cpp
#	g++ embed_lua.cpp -o embed_lua -I/usr/include/lua5.2/ -llua5.2 -Wall

#fxn_lua : fxn_lua.cpp
#	g++ fxn_lua.cpp -o fxn_lua -I/usr/include/lua5.2/ -llua5.2 -ldl -Wall


clean : 
	rm -r embed run #fxn_lua


	#g++ embed_lua.cpp -o embed_lua -I/usr/include/lua5.2/ -Llua-5.2/lib/ -llua5.2 -Wall
