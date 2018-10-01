#!/bin/sh

set -e

export CC=clang-7
export CXX=clang++-7

RUN_FIND_ALL_SYMBOLS=/usr/lib/llvm-7/share/clang/run-find-all-symbols.py
FIND_ALL_SYMBOLS=/usr/bin/find-all-symbols-7

mkdir build || true
cd build
cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
    -DCMAKE_CXX_CLANG_TIDY:STRING='clang-tidy-7;-checks=-*,readability-*' \
    ..

$RUN_FIND_ALL_SYMBOLS -binary "$FIND_ALL_SYMBOLS"

ln -sf $PWD/find_all_symbols_db.yaml ..
ln -sf $PWD/compile_commands.json ..
