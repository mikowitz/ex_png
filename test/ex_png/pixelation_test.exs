defmodule ExPng.Image.PixelationTest do
  use ExUnit.Case
  use ExPng.Constants

  alias ExPng.Color
  alias ExPng.Image.Pixelation

  describe "to_pixels" do
    test "it returns the correct pixels for a 1bit grayscale image" do
      with {:ok, canvas} <- ExPng.Image.from_file("test/png_suite/basic/basn0g01.png") do
        check_pixel_dimensions(canvas)

        pixels = Enum.at(canvas.pixels, 0)
        assert Enum.at(pixels, 0) == Color.white()
        assert Enum.at(pixels, -1) == Color.black()
      end
    end

    test "it returns the correct pixels for a 2bit grayscale image" do
      with {:ok, canvas} <- ExPng.Image.from_file("test/png_suite/basic/basn0g02.png") do
        check_pixel_dimensions(canvas)

        pixels = Enum.at(canvas.pixels, 0)
        assert Enum.at(pixels, 0) == Color.black()
        assert Enum.at(pixels, 4) == Color.grayscale(85)
        assert Enum.at(pixels, 8) == Color.grayscale(170)
        assert Enum.at(pixels, 12) == Color.white()
        assert Enum.at(pixels, 16) == Color.black()
      end
    end

    test "it returns the correct pixels for a 4bit grayscale image" do
      with {:ok, canvas} <- ExPng.Image.from_file("test/png_suite/basic/basn0g04.png") do
        check_pixel_dimensions(canvas)

        pixels = Enum.at(canvas.pixels, 0)
        assert Enum.at(pixels, 0) == Color.black()
        assert Enum.at(pixels, 8) == Color.grayscale(34)
        assert Enum.at(pixels, 16) == Color.grayscale(68)
        assert Enum.at(pixels, 24) == Color.grayscale(102)

        pixels = Enum.at(canvas.pixels, -1)
        assert Enum.at(pixels, 0) == Color.grayscale(119)
        assert Enum.at(pixels, 8) == Color.grayscale(153)
        assert Enum.at(pixels, 16) == Color.grayscale(187)
        assert Enum.at(pixels, 24) == Color.grayscale(221)
      end
    end

    test "it returns the correct pixels for a 8bit grayscale image" do
      with {:ok, image} <- ExPng.Image.from_file("test/png_suite/basic/basn0g08.png") do
        check_pixel_dimensions(image)
      end
    end

    test "it returns the correct pixels for a 16bt grayscale image" do
      with {:ok, image} <- ExPng.Image.from_file("test/png_suite/basic/basn0g16.png") do
        check_pixel_dimensions(image)
      end
    end

    test "it returns the correct pixels for a 8bit truecolor image" do
      with {:ok, image} <- ExPng.Image.from_file("test/png_suite/basic/basn2c08.png") do
        check_pixel_dimensions(image)
      end
    end

    test "it returns the correct pixels for a 16bit truecolor image" do
      with {:ok, image} <- ExPng.Image.from_file("test/png_suite/basic/basn2c16.png") do
        check_pixel_dimensions(image)
      end
    end

    test "it returns the correct pixels for a 1bit indexed image" do
      with {:ok, image} <- ExPng.Image.from_file("test/png_suite/basic/basn3p01.png") do
        check_pixel_dimensions(image)
      end
    end

    test "it returns the correct pixels for a 2bit indexed image" do
      with {:ok, image} <- ExPng.Image.from_file("test/png_suite/basic/basn3p02.png") do
        check_pixel_dimensions(image)
      end
    end

    test "it returns the correct pixels for a 4bit indexed image" do
      with {:ok, image} <- ExPng.Image.from_file("test/png_suite/basic/basn3p04.png") do
        check_pixel_dimensions(image)
      end
    end

    test "it returns the correct pixels for a 8bit indexed image" do
      with {:ok, image} <- ExPng.Image.from_file("test/png_suite/basic/basn3p08.png") do
        check_pixel_dimensions(image)
      end
    end

    test "it returns the correct pixels for a 8bit grayscale alpha image" do
      with {:ok, image} <- ExPng.Image.from_file("test/png_suite/basic/basn4a08.png") do
        check_pixel_dimensions(image)
      end
    end

    test "it returns the correct pixels for a 16bit grayscale alpha image" do
      with {:ok, image} <- ExPng.Image.from_file("test/png_suite/basic/basn4a16.png") do
        check_pixel_dimensions(image)
      end
    end

    test "it returns the correct pixels for a 8bit truecolor alpha image" do
      with {:ok, image} <- ExPng.Image.from_file("test/png_suite/basic/basn6a08.png") do
        check_pixel_dimensions(image)
      end
    end

    test "it returns the correct pixels for a 16bit truecolor alpha image" do
      with {:ok, image} <- ExPng.Image.from_file("test/png_suite/basic/basn6a16.png") do
        check_pixel_dimensions(image)
      end
    end
  end

  describe "from_pixels" do
    setup do
      pixels = [
        Color.black(), Color.white(),
        Color.rgb(10, 20, 30), Color.rgba(10, 20, 255, 40),
        Color.grayscale(80), Color.grayscale(40, 60)
      ]
      {:ok, pixels: pixels}
    end

    test "grayscale, bit depth 1", context do
      assert Pixelation.from_pixels(context.pixels, 1, @grayscale) == <<80>>
    end

    test "grayscale, bit depth 8", context do
      assert Pixelation.from_pixels(context.pixels, 8, @grayscale) ==
        <<0, 255, 30, 255, 80, 40>>
    end

    test "indexed, bit_depth 4", context do
      palette = Enum.sort(context.pixels)
      assert Pixelation.from_pixels(context.pixels, 4, @indexed, palette) ==
        <<5, 18, 67>>
    end

    test "indexed, bit_depth 8", context do
      palette = Enum.sort(context.pixels)
      assert Pixelation.from_pixels(context.pixels, 8, @indexed, palette) ==
      <<0, 5, 1, 2, 4, 3>>
    end

    test "grayscale alpha, bit depth 8", context do
      assert Pixelation.from_pixels(context.pixels, 8, @grayscale_alpha) ==
        <<0, 255, 255, 255, 30, 255, 255, 40, 80, 255, 40, 60>>
    end

    test "truecolor, bit depth 8", context do
      assert Pixelation.from_pixels(context.pixels, 8, @truecolor) ==
        <<0, 0, 0, 255, 255, 255, 10, 20, 30, 10, 20, 255, 80, 80, 80, 40, 40, 40>>
    end

    test "truecolor alpha, bit depth 8", context do
      assert Pixelation.from_pixels(context.pixels, 8, @truecolor_alpha) ==
        <<0, 0, 0, 255, 255, 255, 255, 255,
        10, 20, 30, 255, 10, 20, 255, 40,
        80, 80, 80, 255, 40, 40, 40, 60>>
    end
  end

  defp check_pixel_dimensions(canvas) do
    image = canvas.raw_data
    assert length(canvas.pixels) == image.header_chunk.height

    for pixels <- canvas.pixels do
      assert length(pixels) == image.header_chunk.width
    end
  end
end
