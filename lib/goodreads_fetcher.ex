defmodule GoodreadsFetcher do
  def fetch_by_isbn(isbn \\ "9788366173316") do
    do_fetch("https://www.goodreads.com/book/isbn/#{isbn}?key=#{api_key()}")
  end

  def fetch_by_id(goodreads_id \\ "34841072") do
    do_fetch("https://www.goodreads.com/book/show/#{goodreads_id}?key=#{api_key()}")
  end

  defp do_fetch(fetch_url) do
    case HTTPoison.get(fetch_url) do
      {:ok, %HTTPoison.Response{body: body, status_code: 200}} ->
        %{
          "GoodreadsResponse" => %{
            "book" => %{
              "id" => id,
              "title" => title,
              "language_code" => language_code,
              "isbn" => isbn,
              "isbn13" => isbn13,
              "image_url" => image_url,
              "small_image_url" => small_image_url,
              "description" => description,
              "average_rating" => average_rating,
              "num_pages" => num_pages,
              "ratings_count" => ratings_count,
              "authors" => %{
                "author" => authors
              },
              "work" => %{
                "id" => %{
                  "#content" => work_id
                },
                "best_book_id" => %{
                  "#content" => best_book_id
                },
                "rating_dist" => rating_dist,
                "original_title" => original_title,
                "ratings_count" => %{
                  "#content" => work_ratings_count
                },
                "text_reviews_count" => %{
                  "#content" => text_reviews_count
                },
                "original_publication_year" => %{
                  "#content" => original_publication_year
                },
                "books_count" => %{
                  "#content" => books_count
                }
              }
            }
          }
        } = XmlToMap.naive_map(body)

        [fives, fours, threes, twos, ones, _] =
          String.split(rating_dist, "|")
          |> Stream.map(&String.split(&1, ":"))
          |> Stream.map(fn [_, count] -> count end)
          |> Enum.to_list()

        {:ok,
         %{
           book_id: nil,
           goodreads_book_id: parse_int!(id),
           best_book_id: parse_int!(best_book_id),
           work_id: parse_int!(work_id),
           books_count: parse_int!(books_count),
           isbn: isbn,
           isbn13: isbn13,
           authors: author(authors),
           original_publication_year: parse_int!(original_publication_year),
           original_title: nil_if_empty(original_title),
           title: title,
           language_code: language_code,
           average_rating: parse_float!(average_rating),
           ratings_count: parse_int!(ratings_count),
           work_ratings_count: parse_int!(work_ratings_count),
           work_text_reviews_count: parse_int!(text_reviews_count),
           ratings_1: parse_int!(ones),
           ratings_2: parse_int!(twos),
           ratings_3: parse_int!(threes),
           ratings_4: parse_int!(fours),
           ratings_5: parse_int!(fives),
           image_url: nil_if_empty(image_url),
           small_image_url: nil_if_empty(small_image_url),
           num_pages: parse_int!(num_pages),
           description: process_description(description)
         }}

      _ ->
        {:error, "book can't be fetched"}
    end
  end

  defp nil_if_empty(map) when map == %{}, do: nil

  defp nil_if_empty(map), do: map

  defp process_description(nil), do: nil

  defp process_description(description) do
    description
    |> remove_html_tags()
    |> compact_spaces()
    |> String.replace("\n", "")
    |> String.trim()
  end

  defp remove_html_tags(text), do: Regex.replace(~r/<.+?>/, text, " ")

  defp compact_spaces(text), do: Regex.replace(~r/[ ]{2,}/, text, " ")

  defp parse_int!(nil), do: nil

  defp parse_int!(value) do
    {parsed, _} = Integer.parse(value)
    parsed
  end

  defp parse_float!(nil), do: nil

  defp parse_float!(value) do
    {parsed, _} = Float.parse(value)
    parsed
  end

  defp author(authors) when is_list(authors),
    do: authors |> Stream.map(&author/1) |> Enum.join(", ")

  defp author(%{"name" => name}), do: name

  defp api_key(), do: System.get_env("GOODREADS_API_KEY")
end
