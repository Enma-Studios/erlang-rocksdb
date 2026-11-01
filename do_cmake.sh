#!/bin/sh -x

# Resolve the NIF source. With nothing set, a release-built NIF is
# fetched whenever the tree provably matches a published release; any
# miss (unreleased tree, unsupported platform, network) falls back to
# the source build below. Knobs:
#   ERLANG_ROCKSDB_PREBUILT=1  require the prebuilt, fail when unavailable
#   ERLANG_ROCKSDB_PREBUILT=0  always build from source
#   ERLANG_ROCKSDB_OPTS set    implies a source build (cmake options on a
#                               downloaded binary make no sense)
MODE=auto
if [ "${ERLANG_ROCKSDB_PREBUILT}" = "1" ]; then
    MODE=required
elif [ "${ERLANG_ROCKSDB_PREBUILT}" = "0" ]; then
    MODE=off
elif [ -n "${ERLANG_ROCKSDB_OPTS}" ]; then
    echo "do_cmake: ERLANG_ROCKSDB_OPTS is set, building rocksdb from source"
    MODE=off
fi

# Auto mode may only use binaries that match this tree: HEAD exactly at
# the release tag for the app version, and no local edits to the native
# parts. Without a .git (hex-style packaged tree) the package version is
# the release by construction, so binaries are trusted.
at_published_release() {
    git rev-parse --git-dir >/dev/null 2>&1 || return 0
    VSN=$(sed -n 's/.*{vsn, *"\([^"]*\)".*/\1/p' src/rocksdb.app.src | head -1)
    [ -n "$VSN" ] || return 1
    git describe --exact-match --tags HEAD 2>/dev/null | grep -qx "v$VSN" || return 1
    git diff --quiet HEAD -- c_src src deps rebar.config 2>/dev/null || return 1
    git diff --cached --quiet -- c_src src deps rebar.config 2>/dev/null || return 1
    return 0
}

if [ "$MODE" = "required" ] || { [ "$MODE" = "auto" ] && at_published_release; }; then
    if ./do_prebuilt.sh; then
        mkdir -p _build
        echo ok > _build/prebuilt.flag
        exit 0
    fi
    if [ "$MODE" = "required" ]; then
        echo "do_cmake: ERLANG_ROCKSDB_PREBUILT=1 but no usable prebuilt" >&2
        exit 1
    fi
    echo "do_cmake: no usable prebuilt, falling back to the rocksdb source build"
fi

rm -f _build/prebuilt.flag
mkdir -p _build/cmake
cd _build/cmake

if type cmake3 > /dev/null 2>&1 ; then
    CMAKE=cmake3
else
    CMAKE=cmake
fi

${CMAKE} "$@" ../../c_src || exit 1

echo done.
