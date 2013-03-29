all: tests

tests:
	mkdir -p build
	clang SGPromise.m tests.m -Wall -o build/tests -ObjC -framework Foundation

clean:
	rm -rf build

run:
	build/tests

debug:
	lldb build/tests
