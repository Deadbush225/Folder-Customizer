
icon_refresher: icon_refresher.o
	g++ icon_refresher.o -o icon_refresher.exe

icon_refresher.o: icon_refresher.cpp icon_refresher.h
	g++ -c icon_refresher.cpp -I C:\local\boost_1_80_0

clean:
	del *.o icon_refresher.exe