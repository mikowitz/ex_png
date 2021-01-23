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

defimpl Inspect, for: ExPng.Pixel do
  import Inspect.Algebra

  def inspect(%ExPng.Pixel{r: r, g: g, b: b, a: a}, _opts) do
    use Bitwise

    pixel =
      ((r <<< 24) + (g <<< 16) + (b <<< 8) + a)
      |> Integer.to_string(16)
      |> String.downcase()
      |> String.pad_leading(8, "0")

    concat(["0x", pixel])
  end
end
