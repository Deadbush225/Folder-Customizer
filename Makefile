# CFLAGS := -I C:\local\boost_1_80_0 -D_GLIBCXX_USE_CXX11_ABI=0
# LDFLAGS := -L C:\local\boost_1_80_0\libs -lboost_program_options
# DF := -Wall -Wextra -pedantic -O2
LDFLAGS := -lboost_program_options-mt
# CFLAGS := -I C:\msys64\mingw64\include

icon_refresher: icon_refresher.o
	g++ -g icon_refresher.o -o icon_refresher.exe $(LDFLAGS)

icon_refresher.o: icon_refresher.cpp icon_refresher.h
	g++ -g -c icon_refresher.cpp

clean:
	del *.o icon_refresher.exe