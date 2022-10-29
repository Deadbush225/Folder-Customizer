# CFLAGS := -I C:\local\boost_1_80_0 -D_GLIBCXX_USE_CXX11_ABI=0
# LDFLAGS := -L C:\local\boost_1_80_0\libs -lboost_program_options
# DF := -Wall -Wextra -pedantic -O2
LDFLAGS := -lboost_program_options-mt
DEBUGFL := -g3 -std=c++11
# CFLAGS := -I C:\msys64\mingw64\include

tagger: tagger.o
	g++ tagger.o -o tagger.exe

tagger.o: tagger.cpp
	g++ -o tagger.cpp

# icon_refresher_copy: icon_refresher_copy.o
# 	g++ -std=c++20 -g3 icon_refresher_copy.o -o icon_refresher_copy.exe $(LDFLAGS)

# icon_refresher_copy.o: icon_refresher_copy.cpp
# 	g++ -std=c++20 -g3 -c icon_refresher_copy.cpp

icon_refresher: icon_refresher.o
	g++ -std=c++20 -g3 icon_refresher.o -o icon_refresher.exe $(LDFLAGS)

icon_refresher.o: icon_refresher.cpp icon_refresher.h
	g++ -std=c++20 -g3 -c icon_refresher.cpp

clean:
	del *.o icon_refresher.exe