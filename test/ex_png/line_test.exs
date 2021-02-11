defmodule ExPng.Image.LineTest do
  use ExUnit.Case

  alias ExPng.{Image.Line, Pixel}

  doctest Line

  describe "filtering" do
    test "should decode a line without filtering as is" do
      line = %Line{
        filter_type: 0,
        data: <<255, 255, 255, 255, 255, 255, 255, 255, 255>>
      }

      filtered = Line.filter_pass(line, 3)
      assert filtered.data == <<255, 255, 255, 255, 255, 255, 255, 255, 255>>
    end

    test "should decode a line with sub filtering correctly" do
      line = %Line{
        filter_type: 1,
        data: <<255, 255, 255, 0, 0, 0, 0, 0, 0>>
      }

      filtered = Line.filter_pass(line, 3)
      assert filtered.data == <<255, 255, 255, 255, 255, 255, 255, 255, 255>>

      line = %Line{
        filter_type: 1,
        data: <<0, 0, 0, 0, 0, 0, 0, 0, 0>>
      }

      filtered = Line.filter_pass(line, 3)
      assert filtered.data == <<0, 0, 0, 0, 0, 0, 0, 0, 0>>

      line = %Line{
        filter_type: 1,
        data: <<255, 0, 45, 0, 255, 0, 112, 200, 178>>
      }

      filtered = Line.filter_pass(line, 3)
      assert filtered.data == <<255, 0, 45, 255, 255, 45, 111, 199, 223>>
    end

    test "should decode a line with up filtering correctly" do
      prev = %Line{
        filter_type: 2,
        data: <<255, 255, 255, 127, 127, 127, 0, 0, 0>>
      }

      line = %Line{
        filter_type: 2,
        data: <<0, 127, 255, 0, 127, 255, 0, 127, 255>>
      }

      filtered = Line.filter_pass(line, 3, prev)
      assert filtered.data == <<255, 126, 254, 127, 254, 126, 0, 127, 255>>
    end

    test "should decode a line with average filtering correctly" do
      prev = %Line{
        filter_type: 3,
        data: <<10, 20, 30, 40, 50, 60, 70, 80, 80, 100, 110, 120>>
      }

      line = %Line{
        filter_type: 3,
        data: <<0, 0, 10, 23, 15, 13, 23, 63, 38, 60, 253, 53>>
      }

      filtered = Line.filter_pass(line, 3, prev)
      assert filtered.data == <<5, 10, 25, 45, 45, 55, 80, 125, 105, 150, 114, 165>>
    end

    test "should decode a line with Paeth filtering correctly" do
      prev = %Line{
        filter_type: 4,
        data: <<10, 20, 30, 40, 50, 60, 70, 80, 80, 100, 110, 120>>
      }

      line = %Line{
        filter_type: 4,
        data: <<0, 0, 10, 20, 10, 0, 0, 40, 10, 20, 190, 0>>
      }

      filtered = Line.filter_pass(line, 3, prev)
      assert filtered.data == <<10, 20, 40, 60, 60, 60, 70, 120, 90, 120, 54, 120>>
    end
  end

  describe "to_pixels" do
    test "it returns the correct pixels for a 1bit grayscale image" do
      with {:ok, canvas} <- ExPng.Image.from_file("test/png_suite/basic/basn0g01.png") do
        check_pixel_dimensions(canvas)

        pixels = Enum.at(canvas.pixels, 0)
        assert Enum.at(pixels, 0) == Pixel.white()
        assert Enum.at(pixels, -1) == Pixel.black()
      end
    end

    test "it returns the correct pixels for a 2bit grayscale image" do
      with {:ok, canvas} <- ExPng.Image.from_file("test/png_suite/basic/basn0g02.png") do
        check_pixel_dimensions(canvas)

        pixels = Enum.at(canvas.pixels, 0)
        assert Enum.at(pixels, 0) == Pixel.black()
        assert Enum.at(pixels, 4) == Pixel.grayscale(85)
        assert Enum.at(pixels, 8) == Pixel.grayscale(170)
        assert Enum.at(pixels, 12) == Pixel.white()
        assert Enum.at(pixels, 16) == Pixel.black()
      end
    end

    test "it returns the correct pixels for a 4bit grayscale image" do
      with {:ok, canvas} <- ExPng.Image.from_file("test/png_suite/basic/basn0g04.png") do
        check_pixel_dimensions(canvas)

        pixels = Enum.at(canvas.pixels, 0)
        assert Enum.at(pixels, 0) == Pixel.black()
        assert Enum.at(pixels, 8) == Pixel.grayscale(34)
        assert Enum.at(pixels, 16) == Pixel.grayscale(68)
        assert Enum.at(pixels, 24) == Pixel.grayscale(102)

        pixels = Enum.at(canvas.pixels, -1)
        assert Enum.at(pixels, 0) == Pixel.grayscale(119)
        assert Enum.at(pixels, 8) == Pixel.grayscale(153)
        assert Enum.at(pixels, 16) == Pixel.grayscale(187)
        assert Enum.at(pixels, 24) == Pixel.grayscale(221)
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

  defp check_pixel_dimensions(canvas) do
    image = canvas.raw_data
    assert length(canvas.pixels) == image.header_chunk.height

    for pixels <- canvas.pixels do
      assert length(pixels) == image.header_chunk.width
    end
  end
end
