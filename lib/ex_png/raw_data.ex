defmodule ExPng.RawData do
  @moduledoc """
  This struct provides an intermediate data format between a PNG image file and
  and `ExPng.Image` struct. Raw image file data is parsed into this struct
  when reading from a PNG file, and when turning an `ExPng.Image` into a
  saveable image file.

  This data can be accessed via the `raw_data` field on an `ExPng.Image` struct,
  but users have no need to manipulate this data directly.
  """

  @signature <<0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A>>

  alias ExPng.Chunks
  alias Chunks.{Ancillary, End, Header, ImageData, Palette}

  @type t :: %__MODULE__{
    header_chunk: Header.t,
    data_chunk: ImageData.t,
    palette_chunk: Palette.t,
    ancillary_chunks: [Ancillary.t],
    end_chunk: End.t,
  }
  defstruct [
    :header_chunk,
    :data_chunk,
    :palette_chunk,
    :ancillary_chunks,
    :end_chunk,
  ]

  @doc false
  def from_file(filename) do
    with {:ok, @signature <> data} <- File.read(filename),
         {:ok, header_chunk, data} <- parse_ihdr(data),
         {:ok, chunks} <- parse_chunks(data, []),
         {:ok, raw_data} <- from_chunks(header_chunk, chunks) do
      {:ok, raw_data}
    else
      # file cannot be read
      {:error, error} -> {:error, error, filename}
      # file read, but cannot be parsed as a valid PNG
      {:ok, _data} -> {:error, "malformed PNG signature", filename}
      # error during parsing the PNG data
      {:error, error, _data} -> {:error, error, filename}
    end
  end

  @doc false
  def to_file(%__MODULE__{} = raw_data, filename, encoding_options \\ []) do
    image_data = ImageData.to_bytes(raw_data.data_chunk, encoding_options)

    palette_data = case raw_data.palette_chunk do
      nil -> ""
      palette -> Palette.to_bytes(palette)
    end

    data =
      @signature <>
        Header.to_bytes(raw_data.header_chunk) <>
        palette_data <>
        image_data <>
        End.to_bytes(raw_data.end_chunk)

    File.write(filename, data)
  end

  ## PRIVATE

  defp parse_ihdr(
         <<13::32, "IHDR"::bytes, header_data::bytes-size(13), crc::32, rest::binary>> = data
       ) do
    case validate_crc("IHDR", header_data, crc) do
      true ->
        case Chunks.from_type(:IHDR, header_data) do
          {:ok, header_chunk} -> {:ok, header_chunk, rest}
          error -> error
        end

      false ->
        {:error, "malformed IHDR", data}
    end
  end

  defp parse_ihdr(data), do: {:error, "malformed IHDR", data}

  defp parse_chunks(_, [%End{} | _] = chunks), do: {:ok, Enum.reverse(chunks)}

  defp parse_chunks(
         <<size::32, type::bytes-size(4), chunk_data::bytes-size(size), crc::32, rest::binary>> =
           data,
         chunks
       ) do
    case validate_crc(type, chunk_data, crc) do
      true ->
        with {:ok, new_chunk} <- Chunks.from_type(String.to_atom(type), chunk_data) do
          parse_chunks(rest, [new_chunk | chunks])
        end

      false ->
        {:error, "malformed #{type}", data}
    end
  end

  defp from_chunks(header_chunk, chunks) do
    with {:ok, data_chunks, chunks} <- find_image_data(chunks),
         {:ok, end_chunk, chunks} <- find_end(chunks),
         {:ok, palette, chunks} <- find_palette(chunks, header_chunk) do
      {
        :ok,
        %__MODULE__{
          header_chunk: header_chunk,
          data_chunk: ImageData.merge(data_chunks),
          end_chunk: end_chunk,
          palette_chunk: palette,
          ancillary_chunks: chunks
        }
      }
    else
      error -> error
    end
  end

  defp find_image_data(chunks) do
    case Enum.split_with(chunks, &(&1.type == :IDAT)) do
      {[], _} -> {:error, "missing IDAT chunks"}
      {image_data, chunks} -> {:ok, image_data, chunks}
    end
  end

  defp find_end(chunks) do
    case find_chunk(chunks, :IEND) do
      nil -> {:error, "missing IEND chunk"}
      chunk -> {:ok, chunk, Enum.reject(chunks, fn c -> c == chunk end)}
    end
  end

  defp find_palette(chunks, %{color_mode: color_mode}) do
    case {find_chunk(chunks, :PLTE), color_mode} do
      {nil, 3} ->
        {:error, "missing PLTE for color type 3"}

      {plt, ct} when not is_nil(plt) and ct in [0, 4] ->
        {:error, "PLTE present for grayscale image"}

      {plt, _} ->
        {:ok, plt, Enum.reject(chunks, fn c -> c == plt end)}
    end
  end

  defp find_chunk(chunks, type) do
    Enum.find(chunks, &(&1.type == type))
  end

  defp validate_crc(type, data, crc) do
    :erlang.crc32([type, data]) == crc
  end
end
