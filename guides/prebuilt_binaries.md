# Prebuilt binaries

Every release of this library ships ready-built NIF binaries as GitHub
release assets, so you can install `erlang-rocksdb` without compiling
RocksDB, lz4, snappy, zstd and CRoaring — the C++ part of the build is
tens of minutes and several gigabytes of RAM on a laptop, and it needs
cmake plus a C++20 compiler. The build fetches them by default
whenever they can match your tree; see below for when that is.

## Using them

Nothing to set: whenever the tree matches a published release — a git
pin checked out exactly at a release tag, or a hex-style package tree,
where the package version is the release — a plain build fetches the
matching NIF instead of compiling RocksDB:

```sh
rebar3 compile
```

Any miss falls back to the source build automatically: a pin ahead of
the last tag, local edits to the native code, a platform without
assets, or `ERLANG_ROCKSDB_OPTS` being set (cmake options on a
downloaded binary make no sense, so customizing implies building).

The two knobs override the default:

* `ERLANG_ROCKSDB_PREBUILT=1` — require binaries, fail the build when
  none are usable. Add `ERLANG_ROCKSDB_PREBUILT_TAG=latest` when
  pinning beyond the last release.
* `ERLANG_ROCKSDB_PREBUILT=0` — never fetch, always build from source.

A repeat build finds the recorded checksum and skips the download.
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

lz4, snappy and CRoaring are linked in statically. What remains dynamic
depends on the platform: on Linux the C++ standard library
(`libstdc++6`), `libcrypto` (`libssl3` / `openssl-libs`) and zstd when
the build picked a system copy — every release asset lists its exact
dependencies in its `PREBUILT.txt`. On macOS the binaries link
Homebrew's `openssl` and `zstd`, so `brew install openssl zstd` covers
it.

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
