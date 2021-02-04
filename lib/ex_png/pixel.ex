defmodule ExPng.Pixel do
  @moduledoc """
  Represents a single pixel in an image, storing red, green, blue and alpha
  values, or an index when part of a paletted image.
  """

  @type rgba_value :: 0..255
  @type t :: %__MODULE__{
    r: rgba_value,
    g: rgba_value,
    b: rgba_value,
    a: rgba_value,
    index: integer() | nil
  }
  defstruct [:r, :g, :b, :index, a: 255]

  @doc """
  Returns a grayscale pixel with the given value for the red, green, and blue values.

      iex> Pixel.grayscale(100)
      %Pixel{r: 100, g: 100, b: 100, a: 255}

  If a second argument is passed, it sets the alpha value for the pixel.

      iex> Pixel.grayscale(100, 200)
      %Pixel{r: 100, g: 100, b: 100, a: 200}

  """
  # @spec grayscale(number(), number() | nil) :: %__MODULE__.t()
  @spec grayscale(rgba_value, rgba_value | nil) :: __MODULE__.t()
  def grayscale(gray, alpha \\ 255), do: %__MODULE__{r: gray, g: gray, b: gray, a: alpha}

  @doc """
  Returns a pixel with the arguments as the red, green, and blue values

      iex> Pixel.rgb(50, 100, 200)
      %Pixel{r: 50, g: 100, b: 200, a: 255}

  """
  @spec rgb(rgba_value, rgba_value, rgba_value) :: __MODULE__.t()
  def rgb(r, g, b), do: %__MODULE__{r: r, g: g, b: b}

  @doc """
  Returns a pixel with the arguments as the red, green, blue, and alpha values

      iex> Pixel.rgba(20, 100, 100, 75)
      %Pixel{r: 20, g: 100, b: 100, a: 75}

  """
  @spec rgba(rgba_value, rgba_value, rgba_value, rgba_value) :: __MODULE__.t()
  def rgba(r, g, b, a), do: %__MODULE__{r: r, g: g, b: b, a: a}

  @doc """
  Shortcut for returning an opaque black pixel.
  """
  @spec black() :: __MODULE__.t()
  def black, do: grayscale(0)

  @doc """
  Shortcut for returning an opaque white pixel.
  """
  @spec white() :: __MODULE__.t()
  def white, do: grayscale(255)

  @behaviour ExPng.Encodeable

  def to_bytes(%__MODULE__{r: r, g: g, b: b, a: a}, _encoding_options \\ []) do
    <<r, g, b, a>>
  end
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
