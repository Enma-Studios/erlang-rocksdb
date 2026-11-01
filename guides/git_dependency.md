# Using the fork as a git dependency

To consume this fork directly instead of the hex package, pin it to a
commit ref, tag or branch of `Enma-Studios/erlang-rocksdb`.

## rebar3

```erlang
{deps, [
    {rocksdb, {git, "https://github.com/Enma-Studios/erlang-rocksdb.git",
                {ref, "0efc187a"}}}
]}.
```

`{ref, ...}` pins an exact commit (recommended); `{tag, "v3.2.0"}` and
`{branch, "master"}` also work. A git dependency overrides the hex
package of the same name.

## mix

```elixir
def deps do
  [
    {:rocksdb, git: "https://github.com/Enma-Studios/erlang-rocksdb.git",
     ref: "0efc187a"}
  ]
end
```

Use `tag: "v3.2.0"` or `branch: "master"` for a moving pin.

## Skipping the native build

A git pin pairs naturally with the prebuilt mode (see
[Prebuilt Binaries](prebuilt_binaries.md)):

```sh
ERLANG_ROCKSDB_PREBUILT=1 rebar3 compile          # rebar3 projects
ERLANG_ROCKSDB_PREBUILT=1 mix deps.compile rocksdb  # mix projects
```

The fetcher defaults to the release matching the library version
(v3.2.0 at the commit above). When your pin is ahead of the last
published tag — `master` after v3.2.0, for example — set
`ERLANG_ROCKSDB_PREBUILT_TAG=latest`, or build from source by leaving
the variable unset.
