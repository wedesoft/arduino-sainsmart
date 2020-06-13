.SUFFIXES: .rb

GTEST=/usr/src/googletest/googletest
GMOCK=/usr/src/googletest/googlemock
CXX = g++
RSPEC = rspec
RM_F = rm -f

all: all-recursive

check: check-controller check-client

check-controller: test-suite
	./test-suite

check-client:
	$(RSPEC)

upload:
	cd arduino && $(MAKE) upload && cd ..

repl:
	cd arduino && $(MAKE) repl && cd ..

test-suite: test-suite.o gtest-all.o gmock-all.o
	$(CXX) -o $@ test-suite.o gtest-all.o gmock-all.o -lpthread

test-suite.o: test-suite.cc controllerbase.hh calibration.hh profile.hh path.hh
	$(CXX) -c -I$(GMOCK)/include -I$(GTEST)/include -o $@ $<

gtest-all.o: $(GTEST)/src/gtest-all.cc
	$(CXX) -c -I$(GTEST)/include -I$(GTEST) -o $@ $<

gmock-all.o: $(GMOCK)/src/gmock-all.cc
	$(CXX) -c -I$(GMOCK)/include -I$(GTEST)/include -I$(GMOCK) -o $@ $<

clean: clean-recursive clean-local

clean-local:
	$(RM_F) -f test-suite *.o

all-recursive:
	cd arduino && $(MAKE) && cd ..

clean-recursive:
	cd arduino && $(MAKE) clean && cd ..
