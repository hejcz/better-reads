defmodule ElasticWriter do
  def index_books(file \\ "/home/hejcz/work/goodbooks-10k/books.csv") do
    File.stream!(file)
    |> Stream.drop(1)
    |> CSV.decode!()
    |> Stream.map(fn csv_row ->
      ~s({\"book_id\": #{Enum.at(csv_row, 0)},
       \"goodreads_book_id\": #{Enum.at(csv_row, 1)},
       \"best_book_id\": #{Enum.at(csv_row, 2)},
       \"work_id\": #{Enum.at(csv_row, 3)},
       \"books_count\": #{Enum.at(csv_row, 4)},
       \"isbn\": #{float_to_string_no_decimal_places(Enum.at(csv_row, 5))},
       \"isbn13\": #{float_to_string_no_decimal_places(Enum.at(csv_row, 6))},
       \"authors\": \"#{Enum.at(csv_row, 7)}\",
       \"original_publication_year\": #{to_integer(Enum.at(csv_row, 8))},
       \"original_title\": #{remove_quotes(Enum.at(csv_row, 9))},
       \"title\": #{remove_quotes(Enum.at(csv_row, 10))},
       \"language_code\": \"#{Enum.at(csv_row, 11)}\",
       \"average_rating\": #{Enum.at(csv_row, 12)},
       \"ratings_count\": #{Enum.at(csv_row, 13)},
       \"work_ratings_count\": #{Enum.at(csv_row, 14)},
       \"work_text_reviews_count\": #{Enum.at(csv_row, 15)},
       \"ratings_1\": #{Enum.at(csv_row, 16)},
       \"ratings_2\": #{Enum.at(csv_row, 17)},
       \"ratings_3\": #{Enum.at(csv_row, 18)},
       \"ratings_4\": #{Enum.at(csv_row, 19)},
       \"ratings_5\": #{Enum.at(csv_row, 20)},
       \"image_url\": \"#{Enum.at(csv_row, 21)}\",
       \"small_image_url\": \"#{Enum.at(csv_row, 22)}\"})
    end)
    |> Stream.map(
      &HTTPoison.post("localhost:9200/books/_doc", &1, [{"content-type", "application/json"}])
    )
    |> Stream.filter(fn
      {:ok, %HTTPoison.Response{status_code: 201}} -> false
      _ -> true
    end)
    |> Enum.each(&IO.inspect/1)
  end

  # some titles have quotes inside
  defp remove_quotes(nil), do: "null"
  defp remove_quotes(str), do: "\"#{String.replace(str, "\"", "")}\""

  # years should be an integer
  defp to_integer(nil), do: "null"
  defp to_integer(""), do: "null"
  defp to_integer(str), do: elem(Integer.parse(str), 0)

  # isbn are treated are given as floats
  defp float_to_string_no_decimal_places(nil), do: "null"
  defp float_to_string_no_decimal_places(""), do: "null"

  defp float_to_string_no_decimal_places(float_as_str) do
    "\"#{:erlang.float_to_binary(elem(Float.parse(float_as_str), 0), decimals: 0)}\""
  end
end
