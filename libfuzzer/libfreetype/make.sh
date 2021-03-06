#!/bin/bash
#
# Simple template for compiling target with libfuzzer
#

set -e
# set -x

info()    { echo -e "\e[0;34m[*]\e[0m $*"; }
success() { echo -e "\e[0;32m[+]\e[0m $*"; }
warn()    { echo -e "\e[0;33m[!]\e[0m $*"; }
err()     { echo -e "\e[0;31m[!]\e[0m $*"; }

build_libfuzzer()
{
    info "Downloading libfuzzer"
    svn checkout --quiet http://llvm.org/svn/llvm-project/llvm/trunk/lib/Fuzzer
    info "Compiling libfuzzer"
    mkdir -p build && cd build && rm -fr .svn
    ${CC} -g -c -O2 -std=c++11 ../Fuzzer/*.cpp -IFuzzer
    info "Building libfuzzer library"
    ar ruv libFuzzer.a Fuzzer*.o >/dev/null 2>&1
    cd ..
    success "libfuzzer built!"
}

if [ $# -lt 1 ]; then
    err "Missing argument"
    exit 1
fi

CC=`which clang++-3.9`
IN="`realpath \"$1\"`"
OUT=${IN/.cc/}

if [ "$1" = "clean" ]; then
    info "Cleaning stuff"
    rm -fr -- build Fuzzer *.o
    success "Done"
    exit 0
fi

if [ ! -x "${CC}" ]; then
    err "Missing ${CC}"
    warn 'Run `apt-get install clang-3.9`'
    exit 1
fi

shift
LIBS="$@"
LIBFUZZ="build/libFuzzer.a"
CPU="`grep --count processor /proc/cpuinfo`"
FLAGS="-ggdb -O1 -fno-omit-frame-pointer -fsanitize-coverage=trace-cmp -fsanitize=undefined -fno-sanitize-recover=undefined -fsanitize-coverage=edge  -fsanitize=address"

[ ! -f ${LIBFUZZ} ] && build_libfuzzer

info "Building '${OUT}'"
${CC} ${FLAGS} ${IN} ${LIBFUZZ} ${LIBS} -o ${OUT}

success "Success, now you can:"
echo -e "- Start a simple one-core fuzzing run by running \n\t $ ${OUT}"
if [ ${CPU} -gt 1 ]; then
    echo -e "- Or use your ${CPU} cores in parallel by running \n\t $ ${OUT} -workers=${CPU} -jobs=${CPU} -timeout=3000"
fi
exit 0
