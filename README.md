# erlang-rocksdb - Erlang wrapper for RocksDB

[![Build Status](https://github.com/Enma-Studios/erlang-rocksdb/workflows/build/badge.svg)](https://github.com/Enma-Studios/erlang-rocksdb/actions?query=workflow%3Abuild)
[![Hex pm](http://img.shields.io/hexpm/v/rocksdb.svg?style=flat)](https://hex.pm/packages/rocksdb)

**Current version: 3.2.1**

Copyright (c) 2016-2026 Benoît Chesneau

Feedback and pull requests welcome! If a particular feature of RocksDB is important to you, please let me know by opening an issue, and I'll prioritize it.

## Features

- RocksDB 11.12 with snappy 1.2.1, lz4 1.8.3, zstd 1.5.7
- Prebuilt NIF binaries for Linux and macOS (x86_64, aarch64), OTP 26-29
- Erlang 22+ with dirty-nifs enabled
- All basic db operations (get, put, delete, merge, multi_get)
- Wide-column entity API (put_entity, get_entity, iterator_columns)
- Extended statistics API (45+ tickers, 13+ histograms)
- BlobDB support with statistics and lazy loading
- Batch operations support
- Snapshots support
- Checkpoint support
- Column families support with coalescing iterator
- Transaction logs
- Pessimistic transactions with row-level locking
- Backup support
- Erlang merge operator
- Posting list merge operator for inverted indexes
- Compaction filters (declarative rules and Erlang callbacks)
- SST file support (write, ingest, read)
- Customized build support
- Tested on macOS, FreeBSD, Solaris and Linux

## Usage

See the [Doc](https://enma-studios.github.io/erlang-rocksdb/) for more explanation.

> Note: since the version **0.26.0**, `cmake>=3.4` is required to install `erlang-rocksdb`.

## Prebuilt binaries

Nothing to set: when the tree matches a published release (a git pin at a release tag, or a hex-style package tree), `rebar3 compile` fetches a release-built NIF for your OS, architecture and OTP major instead of compiling RocksDB, and falls back to the source build otherwise. `ERLANG_ROCKSDB_PREBUILT=1` requires binaries, `=0` forces a source build.

See [Prebuilt Binaries](https://enma-studios.github.io/erlang-rocksdb/prebuilt_binaries.html) for what is published and the available overrides.

## Using this fork as a dependency

Pin it by git commit ref (overrides the hex package of the same name):

**rebar3**

```erlang
{deps, [
    {rocksdb, {git, "https://github.com/Enma-Studios/erlang-rocksdb.git",
                {ref, "0efc187a"}}}
]}.
```

**mix**

```elixir
{:rocksdb, git: "https://github.com/Enma-Studios/erlang-rocksdb.git", ref: "0efc187a"}
```

`{tag, "v3.2.0"}` / `tag: "v3.2.0"` and `{branch, "master"}` / `branch: "master"` work too. A pin exactly at a release tag uses its prebuilt binaries by default; anything else builds from source. `ERLANG_ROCKSDB_PREBUILT=1` requires binaries (add `ERLANG_ROCKSDB_PREBUILT_TAG=latest` when pinning beyond the last tag), `=0` forces a source build.

## Customized build ##

See the [Customized builds](https://hexdocs.pm/rocksdb/CUSTOMIZED_BUILDS.html) for more information.

## Support

Support, Design and discussions are done via the [Github Tracker](https://github.com/Enma-Studios/erlang-rocksdb/issues).

Professional support is available via [Enki Multimedia](https://enki-multimedia.eu). Contact sales@enki-multimedia.eu.

## License

Erlang RocksDB is licensed under the Apache License 2.
