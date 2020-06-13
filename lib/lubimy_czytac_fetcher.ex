defmodule LubimyCzytacFetcher do
  @spec fetch(integer()) :: Stream.t()
  def fetch(page \\ 1) do
    {:ok, response} =
      HTTPoison.post(
        "https://lubimyczytac.pl/book/standardFilteredDataPageContent?1592049295",
        "page=#{page}&listId=booksFilteredList&category%5B0%5D=41&rating%5B0%5D=0&rating%5B1%5D=10&publishedYear%5B0%5D=1200&publishedYear%5B1%5D=2020&catalogSortBy=ratings-desc",
        [
          {"X-Requested-With", "XMLHttpRequest"},
          {"Content-type", "application/x-www-form-urlencoded; charset=UTF-8"}
        ]
      )

    %{"data" => %{"content" => content}} = Jason.decode!(response.body)
    document = Floki.parse_document!(content)

    Floki.find(document, "a.authorAllBooks__singleTextTitle")
    |> Stream.map(&elem(&1, 1))
    |> Stream.flat_map(fn x -> x end)
    |> Stream.filter(fn {attr_key, _} -> attr_key == "href" end)
    |> Stream.map(&elem(&1, 1))
    |> Stream.map(&("https://lubimyczytac.pl" <> &1))
    # |> Stream.each(fn _ -> :timer.sleep(1000) end)
    |> Stream.each(&IO.inspect/1)
    |> Stream.map(&find_isbn/1)
    |> Stream.map(&String.replace(&1, "-", ""))
    |> Stream.filter(&(&1 != "000000000000"))
    |> Stream.each(&IO.inspect/1)
  end

  def find_isbn(url \\ "https://lubimyczytac.pl/ksiazka/203765/mechaniczny-ksiaze") do
    {:ok, response} = HTTPoison.get(url)
    [_, isbn] = Regex.run(~r/\"isbn\":\"([0-9-a-zA-Z]+)\"/, response.body)
    isbn
  end
end
