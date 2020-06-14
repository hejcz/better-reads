defmodule ExamplePipe do
  @moduledoc """
  Module containing pipes between different sources e.g. fetch isbn from lubimy czytać
  and download book details from goodreads.
  """

  def from_lubimy_czytac_with_other_editions_fallback(page) do
    LubimyCzytacFetcher.fetch(page)
    |> Stream.map(&fetch_book_info/1)
    |> Enum.to_list()
  end

  defp fetch_book_info(lubimy_czytac_book_url) when is_binary(lubimy_czytac_book_url) do
    with {:ok, isbn} <- LubimyCzytacFetcher.find_isbn(lubimy_czytac_book_url),
         {:ok, book_info} <- GoodreadsFetcher.fetch_by_isbn(isbn) do
      book_info
    else
      _ ->
        other_editions =
          LubimyCzytacFetcher.other_editions(lubimy_czytac_book_url) |> Enum.to_list()

        fetch_book_info(other_editions)
    end
  end

  defp fetch_book_info([]) do
    {:error, "no edition matches"}
  end

  defp fetch_book_info([h | t]) do
    with {:ok, isbn} <- LubimyCzytacFetcher.find_isbn(h),
         {:ok, book_info} <- GoodreadsFetcher.fetch_by_isbn(isbn) do
      book_info
    else
      _ ->
        fetch_book_info(t)
    end
  end
end
