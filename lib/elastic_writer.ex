defmodule ElasticWriter do
  def index_books(books_to_index \\ []) do
    books_to_index
    |> Stream.map(
      &HTTPoison.post("localhost:9200/books/_doc", &1, [{"content-type", "application/json"}])
    )
    |> Stream.filter(fn
      {:ok, %HTTPoison.Response{status_code: 201}} -> false
      _ -> true
    end)
  end
end
