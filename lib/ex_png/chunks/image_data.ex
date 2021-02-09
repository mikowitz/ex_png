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
      |> List.flatten()
      |> reduce_to_binary()

    %ExPng.Chunks.ImageData{data: data}
  end

  @behaviour ExPng.Encodeable

  @impl true
  def to_bytes(%__MODULE__{data: data}) do
    data = deflate(data)
    length = byte_size(data)
    type = <<73, 68, 65, 84>>
    crc = :erlang.crc32([type, data])
    <<length::32>> <> type <> data <> <<crc::32>>
  end

  def from_pixels(pixels) do
    data =
      Enum.map(pixels, fn line ->
        Task.async(fn -> line_to_binary(line) end)
      end)
      |> Enum.map(fn task ->
        Task.await(task)
      end)
      |> Enum.reverse()
      |> Enum.reduce(&Kernel.<>/2)

    %__MODULE__{data: data}
  end

  ## PRIVATE

  defp line_to_binary(line) do
    Enum.reduce(line, <<0>>, fn pixel, acc ->
      acc <> <<pixel.r, pixel.g, pixel.b, pixel.a>>
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

  defp deflate(data) do
    zstream = :zlib.open()
    :zlib.deflateInit(zstream)
    deflated_data = :zlib.deflate(zstream, data, :finish)
    :zlib.deflateEnd(zstream)
    :zlib.close(zstream)
    deflated_data
    |> List.flatten()
    |> Enum.reverse()
    |> Enum.reduce(&Kernel.<>/2)
  end
end
