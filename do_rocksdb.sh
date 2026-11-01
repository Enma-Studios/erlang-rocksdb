#!/bin/sh -x

if [ "${ERLANG_ROCKSDB_PREBUILT}" = "1" ]; then
    [ -f priv/liberocksdb.so ] || { echo "prebuilt priv/liberocksdb.so is missing (do_prebuilt.sh failed?)" >&2; exit 1; }
    echo "using prebuilt priv/liberocksdb.so"
    exit 0
fi

cd _build/cmake

if type cmake3 > /dev/null 2>&1 ; then
    CMAKE=cmake3
else
    CMAKE=cmake
fi

case "$@" in
    *-j*)
        ${CMAKE} --build . -- "$@" || exit 1
        ;;
    *)
        CORES=$(getconf _NPROCESSORS_ONLN 2>/dev/null || sysctl -n hw.ncpu)

        if [ "x$CORES" = "x" ]; then
            PAR=""
        else
            PAR="-- -j $CORES"
        fi
        ${CMAKE} --build . $PAR $@ || exit 1
        ;;
esac

echo done.
