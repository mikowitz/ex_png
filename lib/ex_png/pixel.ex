defmodule ExPng.Pixel do
  @moduledoc false

  defstruct [:r, :g, :b, :index, a: 255]

  def black, do: %__MODULE__{r: 0, g: 0, b: 0}
  def white, do: %__MODULE__{r: 255, g: 255, b: 255}

  def grayscale(gray), do: %__MODULE__{r: gray, g: gray, b: gray}
  def grayscale(gray, alpha), do: %__MODULE__{r: gray, g: gray, b: gray, a: alpha}

  def rgb(r, g, b), do: %__MODULE__{r: r, g: g, b: b}
  def rgba(r, g, b, a), do: %__MODULE__{r: r, g: g, b: b, a: a}
end
