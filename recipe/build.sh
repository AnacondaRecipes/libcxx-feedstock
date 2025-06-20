set -ex

LLVM_PREFIX=$PREFIX

if [[ "$target_platform" == osx-* ]]; then
    export CFLAGS="$CFLAGS -isysroot $CONDA_BUILD_SYSROOT"
    export CXXFLAGS="$CXXFLAGS -isysroot $CONDA_BUILD_SYSROOT"
    export LDFLAGS="$LDFLAGS -isysroot $CONDA_BUILD_SYSROOT"
    export INSTALL_NAME_TOOL="/usr/bin/install_name_tool"
    export CMAKE_EXTRA_ARGS="-DCMAKE_OSX_SYSROOT=$CONDA_BUILD_SYSROOT -DLIBCXX_ENABLE_VENDOR_AVAILABILITY_ANNOTATIONS=ON"
fi

export CFLAGS="$CFLAGS -I$LLVM_PREFIX/include -I$BUILD_PREFIX/include"
export LDFLAGS="$LDFLAGS -L$LLVM_PREFIX/lib -Wl,-rpath,$LLVM_PREFIX/lib -L$BUILD_PREFIX/lib -Wl,-rpath,$BUILD_PREFIX/lib"
export PATH="$LLVM_PREFIX/bin:$PATH"

mkdir build

cmake -G Ninja \
    -B build \
    -S runtimes \
    -DLLVM_ENABLE_RUNTIMES="libcxx;libcxxabi;libunwind" \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DCMAKE_BUILD_TYPE=Release \
    -DLIBCXX_INCLUDE_BENCHMARKS=OFF \
    -DLIBCXX_INCLUDE_DOCS=OFF \
    -DLIBCXX_INCLUDE_TESTS=OFF \
    -DLLVM_ENABLE_PER_TARGET_RUNTIME_DIR=OFF \
    $CMAKE_ARGS \
    $CMAKE_EXTRA_ARGS

# For reference, this is how to build a bootstrap version, we might want to do this in a later 
# and/or reorganize these somehow with clangdev, compiler-rt, llvmdev, etc.
# https://libcxx.llvm.org/VendorDocumentation.html#the-bootstrapping-build
# $ cmake -G Ninja -S llvm -B build -DLLVM_ENABLE_PROJECTS="clang"                      \  # Configure
#                                   -DLLVM_ENABLE_RUNTIMES="libcxx;libcxxabi;libunwind" \
#                                   -DLLVM_RUNTIME_TARGETS="<target-triple>"
# $ ninja -C build runtimes                                                                # Build
# $ ninja -C build check-runtimes                                                          # Test
# $ ninja -C build install-runtimes                                                        # Install

# Build
ninja -C build cxx cxxabi unwind

# Install
ninja -C build install-cxx install-cxxabi install-unwind

if [[ "$target_platform" == osx-* ]]; then
    # on osx we point libc++ to the system libc++abi
    $INSTALL_NAME_TOOL -change "@rpath/libc++abi.1.dylib" "/usr/lib/libc++abi.dylib" $PREFIX/lib/libc++.1.0.dylib
fi
