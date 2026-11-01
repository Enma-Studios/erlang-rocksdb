#!/bin/sh
#
# Package a freshly built NIF as a release asset for the prebuilt pipeline.
# Run after a successful `rebar3 compile` (CI does this in the release
# workflow). Produces dist/erocksdb-otp<MAJOR>-<os>-<arch>.tar.gz holding
# priv/erocksdb.so, its sha256 stamp and a PREBUILT.txt manifest, exactly
# the layout do_prebuilt.sh expects on the consuming side.

set -e

ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"

. "$(dirname "$0")/prebuilt_env.sh"

[ -n "$SHA_TOOL" ] || { echo "package_prebuilt: no sha256 tool available" >&2; exit 1; }
[ -f priv/erocksdb.so ] || { echo "package_prebuilt: priv/erocksdb.so not built yet" >&2; exit 1; }

VSN=$(sed -n 's/.*{vsn, *"\([^"]*\)".*/\1/p' src/rocksdb.app.src | head -1)
ROCKSDB_VSN=$(sed -n 's/^#define ROCKSDB_MAJOR //p;s/^#define ROCKSDB_MINOR //p;s/^#define ROCKSDB_PATCH //p' deps/rocksdb/include/rocksdb/version.h | tr '\n' '.' | sed 's/\.$//')
GIT_SHA=${GITHUB_SHA:-$(git rev-parse HEAD 2>/dev/null || echo unknown)}

cat > priv/PREBUILT.txt <<EOF
erlang-rocksdb $VSN prebuilt
rocksdb:    $ROCKSDB_VSN
otp-major:  $OTP_MAJOR
target:     $OS-$ARCH
commit:     $GIT_SHA
compression: bundled static lz4, snappy, zstd and CRoaring
EOF

prebuilt_sha_of priv/erocksdb.so > priv/erocksdb.so.sha256.txt
sed 's/$/  priv\/erocksdb.so/' priv/erocksdb.so.sha256.txt > priv/erocksdb.so.sha256
rm priv/erocksdb.so.sha256.txt

mkdir -p dist
ASSET="dist/erocksdb-otp$OTP_MAJOR-$OS-$ARCH.tar.gz"
tar -czf "$ASSET" priv/erocksdb.so priv/erocksdb.so.sha256 priv/PREBUILT.txt

echo "packaged $ASSET:"
prebuilt_sha_of "$ASSET" | sed 's/^/  sha256: /'
