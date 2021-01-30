defmodule ExPng.Chunks.Palette do
  @moduledoc """
  Representation of the color palette for a PNG image encoded using the
  indexed filter method.
  """

  alias ExPng.Pixel

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

  ## PRIVATE

  defp parse_palette(data) do
    for <<r, g, b <- data>>, do: Pixel.rgb(r, g, b)
  end
end
