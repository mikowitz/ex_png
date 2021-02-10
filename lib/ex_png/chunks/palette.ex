defmodule ExPng.Chunks.Palette do
  @moduledoc """
  Representation of the color palette for a PNG image encoded using the
  indexed filter method.
  """

  alias ExPng.Pixel

  import ExPng.Utilities, only: [reduce_to_binary: 1]

  @type t :: %__MODULE__{
    type: :PLTE,
    data: binary(),
    palette: [ExPng.Pixel.t, ...]
  }
  defstruct [:data, :palette, type: :PLTE]

  @spec new(:PLTE, binary) :: __MODULE__.t
  def new(:PLTE, data) do
    with palette <- parse_palette(data) do
      {:ok, %__MODULE__{data: data, palette: palette}}
    end
  end

  @behaviour ExPng.Encodeable

  @impl true
  def to_bytes(%__MODULE__{palette: palette}, _encoding_options \\ []) do
    data =
      Enum.map(palette, fn pixel -> <<pixel.r, pixel.g, pixel.b>> end)
      |> reduce_to_binary()
    length = byte_size(data)
    type = <<80, 76, 84, 69>>
    crc = :erlang.crc32([type, data])

    <<length::32>> <> type <> data <> <<crc::32>>
  end

  ## PRIVATE

  defp parse_palette(data) do
    for <<r, g, b <- data>>, do: Pixel.rgb(r, g, b)
  end
end
