defmodule ExPng.Image.Pixelation do
  @moduledoc """
  This module contains code for converting between unfiltered bytestrings and
  lists of `t:ExPng.Pixel.t/0`.
  """

  use ExPng.Constants

  alias ExPng.Pixel

  @doc """
  Parses a de-filtered line of pixel data into a list of `ExPng.Pixel` structs
  based on the bit depth and color mode of the image. For images that use the
  `t:ExPng.indexed/0` color mode, the image's `ExPng.Chunks.Palette` data is passed
  as an optional 4th argument.

  In the code below, in the call to `new/2`, 0 represents the `t:ExPng.filter_none/0`
  filter type. In the call to `to_pixels/3`, 1 is the bit depth of the line --
  each piece of a pixel's data is encoded in a single bit -- and 0 is the
  reperesentation of the `t:ExPng.grayscale/0` color mode.

      iex> line = {0, <<21>>}
      iex> ExPng.Image.Pixelation.to_pixels(line, 1, 0)
      [
        ExPng.Pixel.black(), ExPng.Pixel.black(),
        ExPng.Pixel.black(), ExPng.Pixel.white(),
        ExPng.Pixel.black(), ExPng.Pixel.white(),
        ExPng.Pixel.black(), ExPng.Pixel.white()
      ]


  Here, in the call to `to_pixels/3`, 8 shows that each part of a pixel's
  definition -- the red, green, and blue values -- is stored in 8 bits, or 1 byte,
  and the 2 is the code for the `t:ExPng.truecolor/0` color mode.

      iex> line = {0, <<100, 100, 200, 30, 42, 89>>}
      iex> ExPng.Image.Pixelation.to_pixels(line, 8, 2)
      [
        ExPng.Pixel.rgb(100, 100, 200),
        ExPng.Pixel.rgb(30, 42, 89)
      ]

  """
  @spec to_pixels(binary, ExPng.bit_depth, ExPng.color_mode, ExPng.Chunks.Palette.t | nil) :: [ExPng.Pixel.t, ...]
  def to_pixels(line, bit_depth, color_mode, palette \\ nil)

  def to_pixels(data, 1, @grayscale, _) do
    for <<x::1 <- data>>, do: Pixel.grayscale(x * 255)
  end

  def to_pixels(data, 2, @grayscale, _) do
    for <<x::2 <- data>>, do: Pixel.grayscale(x * 85)
  end

  def to_pixels(data, 4, @grayscale, _) do
    for <<x::4 <- data>>, do: Pixel.grayscale(x * 17)
  end

  def to_pixels(data, 8, @grayscale, _) do
    for <<x::8 <- data>>, do: Pixel.grayscale(x)
  end

  def to_pixels(data, 16, @grayscale, _) do
    for <<x, _ <- data>>, do: Pixel.grayscale(x)
  end

  def to_pixels(data, 8, @truecolor, _) do
    for <<r, g, b <- data>>, do: Pixel.rgb(r, g, b)
  end

  def to_pixels(data, 16, @truecolor, _) do
    for <<r, _, g, _, b, _ <- data>>, do: Pixel.rgb(r, g, b)
  end

  def to_pixels(data, depth, @indexed, palette) do
    for <<x::size(depth) <- data>>, do: Enum.at(palette.palette, x)
  end

  def to_pixels(data, 8, @grayscale_alpha, _) do
    for <<x, a <- data>>, do: Pixel.grayscale(x, a)
  end

  def to_pixels(data, 16, @grayscale_alpha, _) do
    for <<x, _, a, _ <- data>>, do: Pixel.grayscale(x, a)
  end

  def to_pixels(data, 8, @truecolor_alpha, _) do
    for <<r, g, b, a <- data>>, do: Pixel.rgba(r, g, b, a)
  end

  def to_pixels(data, 16, @truecolor_alpha, _) do
    for <<r, _, g, _, b, _, a, _ <- data>>, do: Pixel.rgba(r, g, b, a)
  end
end
