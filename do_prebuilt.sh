#!/bin/sh
#
# Fetch a prebuilt erocksdb NIF from the project's GitHub releases and
# install it into priv/, replacing the native cmake build entirely.
#
# Activated by the caller (do_cmake.sh) when ERLANG_ROCKSDB_PREBUILT=1.
#
# Override knobs:
#   ERLANG_ROCKSDB_PREBUILT_REPO   GitHub <owner>/<repo> holding the releases
#                                  (default: Enma-Studios/erlang-rocksdb)
#   ERLANG_ROCKSDB_PREBUILT_TAG    release tag to download from; "latest"
#                                  follows the newest release, otherwise the
#                                  tag matching src/rocksdb.app.src's vsn
#                                  (v<VSN>) is used so a pinned dependency
#                                  gets the binaries it was built for
#   ERLANG_ROCKSDB_PREBUILT_OTP    OTP major the runtime is on, when it
#                                  cannot be detected via erl(1)
#
# Assets are named erocksdb-otp<MAJOR>-<os>-<arch>.tar.gz. NIFs are
# forward-compatible across OTP majors, so when no asset exists for the
# running major the closest older one is used.

set -e

REPO="${ERLANG_ROCKSDB_PREBUILT_REPO:-Enma-Studios/erlang-rocksdb}"
MIN_OTP_MAJOR=26

die() {
    echo "do_prebuilt: $*" >&2
    exit 1
}

. "$(dirname "$0")/tools/prebuilt_env.sh"

if [ -z "$ERLANG_ROCKSDB_PREBUILT_TAG" ]; then
    VSN=$(sed -n 's/.*{vsn, *"\([^"]*\)".*/\1/p' src/rocksdb.app.src | head -1)
    [ -n "$VSN" ] || die "cannot read the version from src/rocksdb.app.src"
    ERLANG_ROCKSDB_PREBUILT_TAG="v$VSN"
fi

if [ "$ERLANG_ROCKSDB_PREBUILT_TAG" = "latest" ]; then
    BASE_URL="https://github.com/$REPO/releases/latest/download"
else
    BASE_URL="https://github.com/$REPO/releases/download/$ERLANG_ROCKSDB_PREBUILT_TAG"
fi

command -v curl >/dev/null 2>&1 || die "curl is required to fetch prebuilts"

# Cached install: keep priv/liberocksdb.so when its checksum still matches the
# recorded one, so repeated rebar3 invocations do not re-download.
if [ -f priv/liberocksdb.so ] && [ -f priv/liberocksdb.so.sha256 ]; then
    CURRENT=$(prebuilt_sha_of priv/liberocksdb.so)
    RECORDED=$(sed 's/ .*//' priv/liberocksdb.so.sha256)
    if [ "$CURRENT" = "$RECORDED" ]; then
        echo "do_prebuilt: priv/liberocksdb.so is already the fetched prebuilt, keeping it"
        exit 0
    fi
fi

# Pick the asset: exact OTP major preferred, older majors are NIF-compatible.
ASSET=""
TRY_MAJOR=""
MAJOR=$OTP_MAJOR
while [ "$MAJOR" -ge "$MIN_OTP_MAJOR" ]; do
    CANDIDATE="erocksdb-otp$MAJOR-$OS-$ARCH.tar.gz"
    if curl -fsILo /dev/null "$BASE_URL/$CANDIDATE"; then
        ASSET="$CANDIDATE"
        TRY_MAJOR=$MAJOR
        break
    fi
    MAJOR=$((MAJOR - 1))
done
[ -n "$ASSET" ] || die "no prebuilt for $OS/$ARCH between OTP $OTP_MAJOR and $MIN_OTP_MAJOR at $BASE_URL (see guides/prebuilt_binaries.md for what is published)"

if [ "$TRY_MAJOR" != "$OTP_MAJOR" ]; then
    echo "do_prebuilt: no asset for OTP $OTP_MAJOR, using the OTP $TRY_MAJOR build (NIFs are forward-compatible)" >&2
fi
echo "do_prebuilt: fetching $BASE_URL/$ASSET"

TMPDIR_PREBUILT=$(mktemp -d)
trap 'rm -rf "$TMPDIR_PREBUILT"' EXIT
curl -fsSL -o "$TMPDIR_PREBUILT/$ASSET" "$BASE_URL/$ASSET"

if curl -fsSL -o "$TMPDIR_PREBUILT/checksums.txt" "$BASE_URL/checksums.txt"; then
    if [ -n "$SHA_TOOL" ]; then
        EXPECTED=$(awk -v a="$ASSET" '$2 == a {print $1}' "$TMPDIR_PREBUILT/checksums.txt")
        if [ -n "$EXPECTED" ]; then
            ACTUAL=$(prebuilt_sha_of "$TMPDIR_PREBUILT/$ASSET")
            [ "$ACTUAL" = "$EXPECTED" ] || die "checksum mismatch for $ASSET (expected $EXPECTED, got $ACTUAL)"
            echo "do_prebuilt: checksum verified"
        fi
    fi
else
    echo "do_prebuilt: no checksums.txt at this release, skipping verification" >&2
fi

rm -f priv/liberocksdb.so priv/liberocksdb.so.sha256 priv/PREBUILT.txt
tar -xzf "$TMPDIR_PREBUILT/$ASSET" -C .
[ -f priv/liberocksdb.so ] || die "$ASSET did not contain priv/liberocksdb.so"

[ -f priv/PREBUILT.txt ] && cat priv/PREBUILT.txt
echo "do_prebuilt: installed $ASSET into priv/"
