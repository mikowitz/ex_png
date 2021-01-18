defmodule ExPng do
  @signature << 0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a >>

  def from_file(filename) do
    with {:ok, @signature <> data} <- File.read(filename),
         {:ok, header_chunk, data} <- parse_ihdr(data),
         {:ok, chunks} <- parse_chunks(data, []),
         {:ok, image} <- ExPng.Image.from_chunks(header_chunk, chunks)
    do
      {:ok, image}
    else
      # file cannot be read
      {:error, error} -> {:error, error, filename}
      # file read, but cannot be parsed as a valid PNG
      {:ok, _data} -> {:error, "malformed PNG signature", filename}
      {:error, error, _data} -> {:error, error, filename}
    end
  end

  defp parse_ihdr(<<13::32, "IHDR"::bytes, header_data::bytes-size(13), crc::32, rest::binary>> = data) do
    case validate_crc("IHDR", header_data, crc) do
      true ->
        with {:ok, header_chunk} <- ExPng.Chunks.from_type("IHDR", header_data) do
          {
            :ok,
            header_chunk,
            rest
          }
        else
          {:error, _, _} = error -> error
        end
      false -> {:error, "malformed IHDR", data}
    end
  end
  defp parse_ihdr(data), do: {:error, "malformed IHDR", data}

  defp validate_crc(type, data, crc) do
    :erlang.crc32([type, data]) == crc
  end

  def parse_chunks(<<>>, chunks), do: {:ok, Enum.reverse(chunks)}
  def parse_chunks(<<size::32, type::bytes-size(4), chunk_data::bytes-size(size), crc::32, rest::binary>> = data, chunks) do
    case validate_crc(type, chunk_data, crc) do
      true ->
        with {:ok, new_chunk} <- ExPng.Chunks.from_type(type, chunk_data) do
          parse_chunks(rest, [new_chunk|chunks])
        end
      false ->
        {:error, "malformed #{type}", data}
    end
  end
  def parse_chunks(data), do: {:error, "malformed data", data}
end
