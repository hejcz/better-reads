# Hello

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `hello` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:hello, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/hello](https://hexdocs.pm/hello).

**Environment variables**

```
export GOODREADS_API_KEY=mykeytogoodreads
```

**Examples**

```
LubimyCzytacFetcher.fetch(2) 
|> Stream.each(fn _ -> :timer.sleep(1000) end) 
|> Stream.map(& GoodreadsFetcher.fetch_by_isbn/1) 
|> Stream.each(& IO.inspect/1) 
|> Enum.to_list()
```