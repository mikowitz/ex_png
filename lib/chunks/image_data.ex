defmodule ExPng.Chunks.ImageData do
  defstruct [:data, type: "IDAT"]

  def new(data)do
    zstream = :zlib.open()
    :zlib.inflateInit(zstream)
    inflated_data = :zlib.inflate(zstream, data)
    :zlib.inflateEnd(zstream)
    :zlib.close(zstream)

    image_data =
      inflated_data
      |> List.flatten
      |> Enum.reduce(<<>>, fn chunk, acc ->
        acc <> chunk
      end)
    {:ok, %__MODULE__{data: image_data}}
  end
end
