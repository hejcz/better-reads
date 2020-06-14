defmodule LubimyCzytacFetcher do
  @moduledoc """
  Integration with https://lubimyczytac.pl/ service. It scraps html using internal API.
  It fetches specified page of fantasy books list and follows links to fing their ISBN.
  """

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
    |> floki_a_to_book_url()
  end

  def find_isbn(url) do
    {:ok, response} = HTTPoison.get(url)
    [_, isbn] = Regex.run(~r/\"isbn\":\"([0-9-a-zA-Z]+)\"/, response.body)
    fixed_isbn = String.replace(isbn, "-", "")

    if fixed_isbn == "000000000000" do
      {:error, "no isbn"}
    else
      {:ok, fixed_isbn}
    end
  end

  def other_editions(url_to_some_edition \\ "https://lubimyczytac.pl/ksiazka/4821058/hobbit") do
    [prefix, suffix] = String.split(url_to_some_edition, "ksiazka", parts: 2)
    new_url = prefix <> "ksiazka/wydania" <> suffix
    {:ok, response} = HTTPoison.get(new_url)
    # some php-style comments in html result in Floki failure
    fixed_body = Regex.replace(~r/\?\/\*[^*]+\*\/\?>/, response.body, "")
    document = Floki.parse_document!(fixed_body)

    Floki.find(document, "#editionsList a.authorAllBooks__singleTextTitle")
    |> floki_a_to_book_url()
  end

  defp floki_a_to_book_url(links) do
    links
    |> Stream.map(&elem(&1, 1))
    |> Stream.flat_map(& &1)
    |> Stream.filter(fn {attr_key, _} -> attr_key == "href" end)
    |> Stream.map(&elem(&1, 1))
    |> Stream.map(&("https://lubimyczytac.pl" <> &1))
  end
end
