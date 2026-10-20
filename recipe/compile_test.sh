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
