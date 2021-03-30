defmodule ExPng do
  @moduledoc """
  ExPng is a pure Elixir implementation of the PNG image format.

  Images can be created by decoding an existing PNG file

      ExPng.Image.from_file("adorable_kittens.png")

  or creating a blank image with a provided width and height

      ExPng.Image.new(200, 100)

  Images can be edited using `ExPng.Image.draw/3`, `ExPng.Image.line/4`,
  `ExPng.Image.clear/2` and `ExPng.Image.erase/1`
  """

  @type maybe(t) :: t | nil

  @type filter_none :: 0
  @type filter_sub :: 1
  @type filter_up :: 2
  @type filter_average :: 3
  @type filter_paeth :: 4

  @type grayscale :: 0
  @type truecolor :: 2
  @type indexed :: 3
  @type grayscale_alpha :: 4
  @type truecolor_alpha :: 6

  @type filter ::
          filter_none
          | filter_sub
          | filter_up
          | filter_average
          | filter_paeth

  @type color_mode ::
          grayscale
          | truecolor
          | indexed
          | grayscale_alpha
          | truecolor_alpha

  @type bit_depth :: 1 | 2 | 4 | 8 | 16
end
