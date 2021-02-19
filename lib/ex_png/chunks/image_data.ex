defmodule ExPng.Chunks.ImageData do
  @moduledoc """
  Stores the raw data of an IDAT image data chunk from a PNG image.

  Since PNG images can be encoded with the image data split between multiple
  IDAT chunks to allow generating an image in a streaming manner, `merge/1`
  provides support for merging multiple chunks into one before being fully
  decoded by `ExPng`.
  """

  use ExPng.Constants

  alias ExPng.{Image, Pixel}
  alias ExPng.Image.{Filtering, Pixelation}

  import ExPng.Utilities, only: [reduce_to_binary: 1]

  @type t :: %__MODULE__{
    data: binary,
    type: :IDAT
  }
  defstruct [:data, type: :IDAT]

  @spec new(:IDAT, binary) :: {:ok, __MODULE__.t}
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

  def from_pixels(image, header, filter_type \\ @filter_none) do
    palette = Image.unique_pixels(image)
    lines =
      Enum.map(image.pixels, fn line ->
        Task.async(fn ->
          Pixelation.from_pixels(line, header.bit_depth, header.color_mode, palette)
        end)
      end)
      |> Enum.map(fn task ->
        Task.await(task)
      end)

    pixel_size = Pixel.pixel_bytesize(header.color_mode, header.bit_depth)
    data = apply_filter(lines, pixel_size, filter_type)

    {%__MODULE__{data: data}, %ExPng.Chunks.Palette{palette: palette}}
  end

  ## PRIVATE

  defp apply_filter([head|_] = lines, pixel_size, filter_type) do
    pad =
      Stream.cycle([<<0>>])
      |> Enum.take(byte_size(head))
      |> Enum.reduce(&Kernel.<>/2)

    Enum.chunk_every([pad|lines], 2, 1, :discard)
    |> Enum.map(fn [prev, line] -> Filtering.apply_filter({filter_type, line}, pixel_size, prev) end)
    |> Enum.map(fn line -> <<filter_type>> <> line end)
    |> reduce_to_binary()
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
