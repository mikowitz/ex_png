defmodule ExPng.Chunks.Palette do
  defstruct [:data, type: "PLTE"]

  def new(data) do
    {:ok, %__MODULE__{data: data}}
  end
end
