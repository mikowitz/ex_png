defmodule ExPng.Chunks.ImageData do
  @moduledoc false

  defstruct [:data, type: "IDAT"]

  def new("IDAT", data) do
    image_data =
      data
      |> inflate()
      |> List.flatten()
      |> reduce_to_binary()

    {:ok, %__MODULE__{data: image_data}}
  end

  def to_bytes(%__MODULE__{data: data}) do
    data = deflate(data)
    length = byte_size(data)
    type = <<73, 68, 65, 84>>
    crc = :erlang.crc32([type, data])
    <<length::32>> <> type <> data <> <<crc::32>>
  end

  def merge([%__MODULE__{} | _] = data_chunks) do
    data =
      data_chunks
      |> Enum.map(& &1.data)
      |> reduce_to_binary()

    %ExPng.Chunks.ImageData{data: data}
  end

  def from_pixels(pixels) do
    data =
      Enum.map(pixels, fn line ->
        Enum.reduce(line, <<0>>, fn pixel, acc ->
          acc <> <<pixel.r, pixel.g, pixel.b, pixel.a>>
        end)
      end)
      |> Enum.reverse()
      |> Enum.reduce(&Kernel.<>/2)

    %__MODULE__{data: data}
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
