defmodule ExPng.PixelTest do
  use ExUnit.Case

  alias ExPng.Pixel
  doctest Pixel

  describe "pixel_bytesize" do
    test "it returns the correct number of bytes for a default bit depth of 8" do
      for {color_mode, bytesize} <- [{0, 1}, {2, 3}, {3, 1}, {4, 2}, {6, 4}] do
        assert Pixel.pixel_bytesize(color_mode) == bytesize
      end
    end

    test "it returns the correct number of bytes for alternative bit depths" do
      assert Pixel.pixel_bytesize(0, 1) == 1
      assert Pixel.pixel_bytesize(0, 16) == 2
      assert Pixel.pixel_bytesize(2, 16) == 6
      assert Pixel.pixel_bytesize(6, 16) == 8
    end

    test "it can calculate from an Image" do
      for file <- Path.wildcard("test/png_suite/basic/*.png") do
        with {:ok, image} <- ExPng.Image.from_file(file) do
          [_, color_mode, bit_depth] = Regex.run(~r/bas[ni](\d+).(\d+)\.png$/, file)

          [color_mode, bit_depth] =
            [color_mode, bit_depth]
            |> Enum.map(&Integer.parse/1)
            |> Enum.map(fn {i, ""} -> i end)

          assert Pixel.pixel_bytesize(image.raw_data) ==
                   Pixel.pixel_bytesize(color_mode, bit_depth)
        end
      end
    end
  end

  describe "line_bytesize" do
    test "it returns the correct number of bytes per line of image data" do
      assert Pixel.line_bytesize(0, 8, 30) == 30
      assert Pixel.line_bytesize(2, 8, 50) == 150
      assert Pixel.line_bytesize(6, 16, 100) == 800
    end

    test "it can calculate from an Image" do
      {:ok, image} = ExPng.Image.from_file("test/png_suite/basic/basn0g01.png")
      assert Pixel.line_bytesize(image.raw_data) == 4
    end
  end

  describe "inspect" do
    test "it returns a 10-character hex representation of the pixel" do
      assert Pixel.black() |> inspect == "0x000000ff"
      assert Pixel.white() |> inspect == "0xffffffff"

      assert Pixel.rgb(254, 0, 0) |> inspect == "0xfe0000ff"
      assert Pixel.rgba(10, 200, 250, 100) |> inspect == "0x0ac8fa64"

      assert Pixel.grayscale(20) |> inspect == "0x141414ff"
      assert Pixel.grayscale(8, 20) |> inspect == "0x08080814"
    end
  end
end
