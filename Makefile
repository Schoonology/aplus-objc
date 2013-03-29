build:
	mkdir -p build
	clang Promise.m tests.m -Wall -o build/tests -ObjC -framework Foundation

run:
	build/tests

debug:
	lldb build/tests
