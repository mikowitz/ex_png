defmodule ExPng do
  @signature << 0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a >>

  def from_file(filename) do
    with {:ok, @signature <> data} <- File.read(filename),
         {:ok, header_chunk, data} <- parse_ihdr(data)
    do
      {:ok, header_chunk}
    else
      # file cannot be read
      {:error, error} -> {:error, error, filename}
      # file read, but cannot be parsed as a valid PNG
      {:ok, _data} -> {:error, "malformed PNG signature", filename}
      {:error, error, _data} -> {:error, error, filename}
    end
  end

  defp parse_ihdr(<<13::32, "IHDR"::bytes, header_data::bytes-size(13), crc::32, rest::binary>> = data) do
    case :erlang.crc32(["IHDR", header_data]) == crc do
      true ->
        with {:ok, header_chunk} <- ExPng.Chunks.Header.new(header_data) do
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
end
