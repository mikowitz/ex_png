defmodule ExPng.Chunks.ImageData do
  @moduledoc """
  Stores the raw data of an IDAT image data chunk from a PNG image.

  Since PNG images can be encoded with the image data split between multiple
  IDAT chunks to allow generating an image in a streaming manner, `merge/1`
  provides support for merging multiple chunks into one before being fully
  decoded by `ExPng`.
  """

  use ExPng.Constants

  alias ExPng.Image
  import ExPng.Utilities, only: [reduce_to_binary: 1]

  @type t :: %__MODULE__{
    data: binary,
    type: :IDAT
  }
  defstruct [:data, type: :IDAT]

  @spec new(:IDAT, binary) :: __MODULE__.t
  def new(:IDAT, data) do
    image_data =
      data
    {:ok, %__MODULE__{data: image_data}}
  end

  @doc """
  Merges a list of ImageData chunks into one
  """
  @spec merge([__MODULE__.t, ...]) :: __MODULE__.t
  def merge([%__MODULE__{} | _] = data_chunks) do
    data =
      data_chunks
      |> Enum.map(& &1.data)
      |> reduce_to_binary()
      |> inflate()
      |> reduce_to_binary()

    %ExPng.Chunks.ImageData{data: data}
  end

  @behaviour ExPng.Encodeable

  @impl true
  def to_bytes(%__MODULE__{data: data}, encoding_options \\ []) do
    compression = Keyword.get(encoding_options, :compression, 6)
    data = deflate(data, compression)
    length = byte_size(data)
    type = <<73, 68, 65, 84>>
    crc = :erlang.crc32([type, data])
    <<length::32>> <> type <> data <> <<crc::32>>
  end

  def from_pixels(image, header) do
    palette = Image.unique_pixels(image)
    data =
      Enum.map(image.pixels, fn line ->
        Task.async(fn -> line_to_binary(line, header, palette) end)
      end)
      |> Enum.map(fn task ->
        Task.await(task)
      end)
      |> reduce_to_binary()

    {%__MODULE__{data: data}, %ExPng.Chunks.Palette{palette: palette}}
  end

  ## PRIVATE

  defp line_to_binary(line, %{color_mode: @indexed} = header, palette) do
    bit_depth = header.bit_depth
    chunk_size = div(8, bit_depth)
    line =
      line
      |> Enum.map(fn pixel -> Enum.find_index(palette, fn p -> p == pixel end) end)
      |> Enum.map(fn i ->
        Integer.to_string(i, 2)
        |> String.pad_leading(bit_depth, "0")
      end)
      |> Enum.chunk_every(chunk_size, chunk_size)
      |> Enum.map(fn byte ->
        byte =
          byte
          |> Enum.join("")
          |> String.pad_trailing(8, "0")
          |> String.to_integer(2)
        <<byte>>
      end)
      |> reduce_to_binary()
    <<0>> <> line
  end

  defp line_to_binary(line, %{bit_depth: 1} = _header, _palette) do
    line =
      line
      |> Enum.map(& div(&1.b, 255))
      |> Enum.chunk_every(8)
      |> Enum.map(fn bits -> Enum.join(bits, "") |> String.to_integer(2) end)
      |> Enum.map(fn byte -> <<byte>> end)
      |> reduce_to_binary()
    <<0>> <> line
  end

  defp line_to_binary(line, %{bit_depth: 8} = header, _palette) do
    Enum.reduce(line, <<0>>, fn pixel, acc ->
      acc <> case header.color_mode do
        @truecolor_alpha -> <<pixel.r, pixel.g, pixel.b, pixel.a>>
        @truecolor -> <<pixel.r, pixel.g, pixel.b>>
        @grayscale_alpha -> <<pixel.b, pixel.a>>
        @grayscale -> <<pixel.b>>
      end
    end)
  end

  defp inflate(data) do
    zstream = :zlib.open()
    :zlib.inflateInit(zstream)
    inflated_data = :zlib.inflate(zstream, data)
    :zlib.inflateEnd(zstream)
    :zlib.close(zstream)
    inflated_data
  end

  defp deflate(data, compression) do
    zstream = :zlib.open()
    :zlib.deflateInit(zstream, compression)
    deflated_data = :zlib.deflate(zstream, data, :finish)
    :zlib.deflateEnd(zstream)
    :zlib.close(zstream)
    deflated_data
    |> reduce_to_binary()
  end
end
