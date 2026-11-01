#!/bin/sh
#
# Shared detection for the prebuilt pipeline: normalizes OS, architecture,
# OTP major and the sha256 tool into OS, ARCH, OTP_MAJOR and SHA_TOOL.
# Sourced by do_prebuilt.sh (fetch side) and tools/package_prebuilt.sh
# (packaging side) so both agree on asset naming.

# ERLANG_ROCKSDB_PREBUILT_OTP overrides OTP detection when erl(1) is not
# usable in the current environment.
if [ -n "$ERLANG_ROCKSDB_PREBUILT_OTP" ]; then
    OTP_MAJOR="$ERLANG_ROCKSDB_PREBUILT_OTP"
elif command -v erl >/dev/null 2>&1; then
    OTP_MAJOR=$(erl -noshell -eval 'io:format("~s",[erlang:system_info(otp_release)]),halt().' 2>/dev/null | tr -d '[:space:]')
else
    echo "prebuilt: cannot detect the OTP release (erl not found); set ERLANG_ROCKSDB_PREBUILT_OTP" >&2
    exit 1
fi
case "$OTP_MAJOR" in
    [0-9]*) ;;
    *) echo "prebuilt: could not determine OTP major release, got '$OTP_MAJOR'" >&2; exit 1 ;;
esac

case "$(uname -s)" in
    Linux)  OS=linux ;;
    Darwin) OS=darwin ;;
    *) echo "prebuilt: unsupported OS $(uname -s)" >&2; exit 1 ;;
esac

case "$(uname -m)" in
    x86_64|amd64)   ARCH=x86_64 ;;
    aarch64|arm64)  ARCH=aarch64 ;;
    *) echo "prebuilt: unsupported architecture $(uname -m)" >&2; exit 1 ;;
esac

SHA_TOOL=""
if command -v sha256sum >/dev/null 2>&1; then
    SHA_TOOL="sha256sum"
elif command -v shasum >/dev/null 2>&1; then
    SHA_TOOL="shasum -a 256"
fi

prebuilt_sha_of() {
    $SHA_TOOL "$1" | awk '{print $1}'
}
