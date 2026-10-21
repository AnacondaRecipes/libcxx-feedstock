set -xe

LINK_FLAGS="-Wl,-rpath,$PREFIX/lib -L$PREFIX/lib -Wl,-v -v"
CXX="clang++"

if [[ "$target_platform" == osx* ]]; then
    llvm-nm $PREFIX/lib/libc++.1.dylib
    # no clangxx in the macOS test env (see meta.yaml); clang in C++ driver mode is the same driver
    CXX="clang --driver-mode=g++"
else
    LINK_FLAGS="${LINK_FLAGS} -lc++abi"
fi

# The package under test must provide both the headers and the runtime: assert the
# compiled-in _LIBCPP_VERSION matches this version and that the binary loads $PREFIX's libc++
IFS=. read -r _maj _min _pat <<< "${PKG_VERSION}"
EXPECTED_LIBCPP_VERSION=$((_maj * 10000 + _min * 100 + _pat))
$CXX -stdlib=libc++ -O2 -g test_sources/check_libcpp_def.cpp $LINK_FLAGS
./a.out | grep -x "_LIBCPP_VERSION is ${EXPECTED_LIBCPP_VERSION}"
if [[ "$target_platform" == osx* ]]; then
    DYLD_PRINT_LIBRARIES=1 ./a.out 2>&1 | grep -F "$PREFIX/lib/libc++.1"
else
    LD_DEBUG=libs ./a.out 2>&1 | grep -F "$PREFIX/lib/libc++.so.1"
fi

FILES=test_sources/*.c
for f in $FILES
do
    clang -O2 -g $f ${LINK_FLAGS}
    ./a.out
done

FILES=test_sources/*.cpp
for f in $FILES
do
    $CXX -stdlib=libc++ -O2 -g $f $LINK_FLAGS
    ./a.out
done

FILES=test_sources/cpp11/*.cpp
for f in $FILES
do
    $CXX -stdlib=libc++ -std=c++11 -O2 -g $f $LINK_FLAGS
    ./a.out
done

FILES=test_sources/cpp14/*.cpp
for f in $FILES
do
    $CXX -stdlib=libc++ -std=c++14 -O2 -g $f $LINK_FLAGS
    ./a.out
done

FILES=test_sources/cpp17/*.cpp
for f in $FILES
do
    $CXX -stdlib=libc++ -std=c++23 -O2 -g $f $LINK_FLAGS
    ./a.out
done
