GTEST=/usr/src/gtest
GMOCK=/usr/src/gmock
CXX = g++

all: all-recursive

check: test-suite
	./test-suite

upload:
	cd arduino && make upload && cd ..

test-suite: test-suite.o gtest-all.o gmock-all.o
	$(CXX) -o $@ test-suite.o gtest-all.o gmock-all.o -lpthread

test-suite.o: test-suite.cc curve.hh controller.hh
	$(CXX) -c -I$(GMOCK)/include -I$(GTEST)/include -o $@ $<

gtest-all.o: $(GTEST)/src/gtest-all.cc
	g++ -c -I$(GTEST)/include -I$(GTEST) -o $@ $<

gmock-all.o: $(GMOCK)/src/gmock-all.cc
	g++ -c -I$(GMOCK)/include -I$(GTEST)/include -I$(GMOCK) -o $@ $<

clean: clean-recursive clean-local

clean-local:
	rm -f test-suite *.o

all-recursive:
	cd arduino && make && cd ..

clean-recursive:
	cd arduino && make clean && cd ..
