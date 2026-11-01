#!/bin/sh -x

if [ "${ERLANG_ROCKSDB_PREBUILT}" = "1" ]; then
    ./do_prebuilt.sh || exit 1
    exit 0
fi

mkdir -p _build/cmake
cd _build/cmake

if type cmake3 > /dev/null 2>&1 ; then
    CMAKE=cmake3
else
    CMAKE=cmake
fi

${CMAKE} "$@" ../../c_src || exit 1

echo done.
