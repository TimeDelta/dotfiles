# abort if not osx
is_osx || return 1

gcc -o bin/realpath compile/realpath.c

# @TODO add compilation command for memshuf.cpp
