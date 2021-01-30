defmodule ExPng.ColorTest do
  use ExUnit.Case

  alias ExPng.Color

  describe "pixel_bytesize" do
    test "it returns the correct number of bytes for a default bit depth of 8" do
      for {color_mode, bytesize} <- [{0, 1}, {2, 3}, {3, 1}, {4, 2}, {6, 4}] do
        assert Color.pixel_bytesize(color_mode) == bytesize
      end
    end

    test "it returns the correct number of bytes for alternative bit depths" do
      assert Color.pixel_bytesize(0, 1) == 1
      assert Color.pixel_bytesize(0, 16) == 2
      assert Color.pixel_bytesize(2, 16) == 6
      assert Color.pixel_bytesize(6, 16) == 8
    end

    test "it can calculate from an Image" do
      for file <- Path.wildcard("test/png_suite/basic/*.png") do
        with {:ok, image} <- ExPng.Image.from_file(file) do
          [_, color_mode, bit_depth] = Regex.run(~r/bas[ni](\d+).(\d+)\.png$/, file)

          [color_mode, bit_depth] =
            [color_mode, bit_depth]
            |> Enum.map(&Integer.parse/1)
            |> Enum.map(fn {i, ""} -> i end)

          assert Color.pixel_bytesize(image.raw_data) ==
                   Color.pixel_bytesize(color_mode, bit_depth)
        end
      end
    end
  end

  describe "line_bytesize" do
    test "it returns the correct number of bytes per line of image data" do
      assert Color.line_bytesize(0, 8, 30) == 30
      assert Color.line_bytesize(2, 8, 50) == 150
      assert Color.line_bytesize(6, 16, 100) == 800
    end

    test "it can calculate from an Image" do
      {:ok, image} = ExPng.Image.from_file("test/png_suite/basic/basn0g01.png")
      assert Color.line_bytesize(image.raw_data) == 4
    end
  end
end
