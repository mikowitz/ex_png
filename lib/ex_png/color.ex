defmodule ExPng.Color do
  @moduledoc """
  Represents a single pixel in an image, storing red, green, blue and alpha
  values.
  """
  use ExPng.Constants

  @type rgba_value :: 0..255
  @type t :: <<_::32>>

  @doc """
  Returns a grayscale pixel with the given value for the red, green, and blue values.

      iex> Color.grayscale(100)
      %Color{r: 100, g: 100, b: 100, a: 255}

  If a second argument is passed, it sets the alpha value for the pixel.

      iex> Pixel.grayscale(100, 200)
      %Pixel{r: 100, g: 100, b: 100, a: 200}

  """
  @spec grayscale(rgba_value, ExPng.maybe(rgba_value)) :: __MODULE__.t()
  # def grayscale(gray, alpha \\ 255), do: %__MODULE__{r: gray, g: gray, b: gray, a: alpha}
  def grayscale(gray, alpha \\ 255), do: <<gray, gray, gray, alpha>>

  @doc """
  Returns a pixel with the arguments as the red, green, and blue values

      iex> Pixel.rgb(50, 100, 200)
      %Pixel{r: 50, g: 100, b: 200, a: 255}

  """
  @spec rgb(rgba_value, rgba_value, rgba_value) :: __MODULE__.t()
  def rgb(r, g, b), do: <<r, g, b, 255>>

  @doc """
  Returns a pixel with the arguments as the red, green, blue, and alpha values

      iex> Pixel.rgba(20, 100, 100, 75)
      %Pixel{r: 20, g: 100, b: 100, a: 75}

  """
  @spec rgba(rgba_value, rgba_value, rgba_value, rgba_value) :: __MODULE__.t()
  def rgba(r, g, b, a), do: <<r, g, b, a>>

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

  @spec opaque?(__MODULE__.t()) :: boolean
  def opaque(<<_, _, _, 255>>), do: true
  def opaque?(_), do: false

  @spec grayscale?(__MODULE__.t()) :: boolean
  def grayscale?(<<gr, gr, gr, _>>), do: true
  def grayscale?(_), do: false

  @spec black_or_white?(__MODULE__.t()) :: boolean
  def black_or_white?(<<0, 0, 0, 255>>), do: true
  def black_or_white?(<<255, 255, 255, 255>>), do: true
  def black_or_white?(_), do: false

  def pixel_bytesize(%ExPng.RawData{header_chunk: header}) do
    pixel_bytesize(header.color_mode, header.bit_depth)
  end

  def pixel_bytesize(color_mode, bit_depth \\ 8) do
    color_mode
    |> pixel_bitsize(bit_depth)
    |> to_bytesize()
  end

  def line_bytesize(%ExPng.RawData{header_chunk: header}) do
    line_bytesize(header.color_mode, header.bit_depth, header.width)
  end

  def line_bytesize(color_mode, bit_depth, width) do
    color_mode
    |> pixel_bitsize(bit_depth)
    |> Kernel.*(width)
    |> to_bytesize()
  end

  defp pixel_bitsize(color_mode, bit_depth) do
    color_mode
    |> channels_for_color_mode()
    |> Kernel.*(bit_depth)
  end

  defp channels_for_color_mode(@grayscale), do: 1
  defp channels_for_color_mode(@truecolor), do: 3
  defp channels_for_color_mode(@indexed), do: 1
  defp channels_for_color_mode(@grayscale_alpha), do: 2
  defp channels_for_color_mode(@truecolor_alpha), do: 4

  defp to_bytesize(x) do
    x
    |> Kernel.+(7)
    |> Bitwise.>>>(3)
  end
end
