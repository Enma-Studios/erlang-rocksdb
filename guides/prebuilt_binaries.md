# Prebuilt binaries

Every release of this library ships ready-built NIF binaries as GitHub
release assets, so you can install `erlang-rocksdb` without compiling
RocksDB, lz4, snappy, zstd and CRoaring — the C++ part of the build is
tens of minutes and several gigabytes of RAM on a laptop, and it needs
cmake plus a C++20 compiler. The prebuilts bundle all four compression
libraries statically; the only runtime dependencies are the system C++
library and OpenSSL's `libcrypto`.

## Using them

Set one environment variable and build as usual:

```sh
ERLANG_ROCKSDB_PREBUILT=1 rebar3 compile
```

The same variable works when `rocksdb` is one of your dependencies, in
`make`, in CI, everywhere rebar3 runs the compile hooks: the build
downloads the matching tarball from the project's GitHub releases,
verifies it against the release's `checksums.txt`, and unpacks
`priv/erocksdb.so` in place of the native build. A repeat build finds
the recorded checksum and skips the download.

If you would rather not type it, export it once per environment:

```sh
export ERLANG_ROCKSDB_PREBUILT=1
rebar3 do clean,compile
```

`rebar3 clean` removes the NIF together with its checksum stamp, so
the next compile fetches again.

## What gets downloaded

Assets are named `erocksdb-otp<MAJOR>-<os>-<arch>.tar.gz`:

| target | published for OTP |
|---|---|
| `linux-x86_64`   | 26, 27, 28, 29 |
| `linux-aarch64`  | 26, 27, 28, 29 |
| `darwin-aarch64` | 26, 27, 28, 29 |
| `darwin-x86_64`  | 26, 27, 28, 29 |

The fetcher detects your OS, architecture and OTP major on its own.
NIFs built against an older OTP major load fine on newer ones, so when
your OTP is newer than the newest published asset — say OTP 30 against
a `otp29` tarball — it takes the closest older asset and says so.

By default it downloads from the release tagged for the version of the
library being compiled (`v3.2.0` for version 3.2.0), which is what a
pinned dependency should get. Two variables override the defaults:

* `ERLANG_ROCKSDB_PREBUILT_TAG=latest` — follow the newest release
  instead of the pinned one, useful when tracking `master`.
* `ERLANG_ROCKSDB_PREBUILT_REPO=<owner>/<repo>` — fetch from a fork or
  a mirror that publishes its own assets.

`ERLANG_ROCKSDB_PREBUILT_OTP=<major>` overrides OTP detection for
environments where `erl` is not on the path when the hooks run.

## Runtime requirements

The NIF keeps only two dynamic dependencies: the platform C++ standard
library and OpenSSL's `libcrypto` (the encrypted-env feature links it).
On Linux both come from your distribution (`libstdc++6`, `libssl3` /
`openssl-libs`). On macOS the binaries are linked against Homebrew's
`openssl@3`, so `brew install openssl@3` covers it.

macOS x86_64 assets are built on Intel runners, aarch64 assets on
Apple Silicon; the two are not interchangeable.

## When there is no prebuilt

Windows and the BSDs have no published assets, and the fetcher errors
out there rather than guessing: just build from source, which remains
the default whenever `ERLANG_ROCKSDB_PREBUILT` is unset. The assets
are built by the `release` workflow from the exact tagged commit, so a
prebuilt always corresponds to a reviewable source tree; each tarball
carries a `PREBUILT.txt` manifest naming the RocksDB version, OTP
major, target and commit it was built from.
