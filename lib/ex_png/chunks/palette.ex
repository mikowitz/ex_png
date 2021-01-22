defmodule ExPng.Chunks.Palette do
  @moduledoc false

  alias ExPng.Pixel

  defstruct [:data, :palette, type: "PLTE"]

  def new("PLTE", data) do
    with palette <- parse_palette(data) do
      {:ok, %__MODULE__{data: data, palette: palette}}
    end
  end

  defp parse_palette(data) do
    for <<r, g, b <- data>>, do: Pixel.rgb(r, g, b)
  end
end
