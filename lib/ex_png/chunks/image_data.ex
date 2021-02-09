defmodule ExPng.Chunks.ImageData do
  @moduledoc """
  Stores the raw data of an IDAT image data chunk from a PNG image.

  Since PNG images can be encoded with the image data split between multiple
  IDAT chunks to allow generating an image in a streaming manner, `merge/1`
  provides support for merging multiple chunks into one before being fully
  decoded by `ExPng`.
  """

  @type t :: %__MODULE__{
    data: binary,
    type: :IDAT
  }
  defstruct [:data, type: :IDAT]

  @doc """
  Returns an `ExPng.Chunks.ImageData` struct from raw
  image data
  """
  @spec new(:IDAT, binary) :: __MODULE__.t
  def new(:IDAT, data) do
    {:ok, %__MODULE__{data: data}}
  end

  @doc """
  Merges a list of `ExPng.Chunks.ImageData` chunks into one
  """
  @spec merge([__MODULE__.t, ...]) :: __MODULE__.t
  def merge([%__MODULE__{} | _] = data_chunks) do
    data =
      data_chunks
      |> Enum.map(& &1.data)
      |> reduce_to_binary()
      |> inflate()
      |> List.flatten()
      |> reduce_to_binary()

    %ExPng.Chunks.ImageData{data: data}
  end

  @behaviour ExPng.Encodeable

  @impl true
  def to_bytes(%__MODULE__{data: data}, encoding_options) do
    compression = Keyword.get(encoding_options, :compression, 6)
    data = deflate(data, compression)
    length = byte_size(data)
    type = <<73, 68, 65, 84>>
    crc = :erlang.crc32([type, data])
    <<length::32>> <> type <> data <> <<crc::32>>
  end

  @doc """
  Convert a 2 dimensional array of `ExPng.Pixel`s
  to an `ExPng.Chunks.ImageData` struct
  """
  @spec from_pixels(ExPng.Image.row, ExPng.color_mode) :: __MODULE__.t
  def from_pixels(pixels, color_mode) do
    this = self()
    data =
      Enum.map(pixels, fn line ->
        spawn(fn -> send this, {self(), line_to_pixels(line, color_mode)} end)
      end)
      |> Enum.map(fn pid ->
        receive do
          {^pid, line} -> line
        end
      end)
      |> Enum.reverse()
      |> Enum.reduce(&Kernel.<>/2)

    %__MODULE__{data: data}
  end

  ## PRIVATE

  defp line_to_pixels(line, color_mode) do
    Enum.reduce(line, <<0>>, fn pixel, acc ->
      acc <> ExPng.Pixel.to_bytes(pixel, color_mode)
    end)
  end

  defp reduce_to_binary(chunks) do
    Enum.reduce(chunks, <<>>, fn chunk, acc ->
      acc <> chunk
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
    |> List.flatten()
    |> Enum.reverse()
    |> Enum.reduce(&Kernel.<>/2)
  end
end
