exp-hull: exp-hull.hs ExpPairs/*.hs
	ghc -O2 exp-hull.hs

tests: tests.hs ExpPairs/*.hs ExpPairs/Tests/*.hs
	ghc -O2 tests.hs

all: exp-hull tests

test: tests
	./tests

clean:
	find -iname "*.hi" -delete -or -iname "*.o" -delete
	rm exp-hull tests
