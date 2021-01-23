defmodule ExPng.ImageTest do
  use ExUnit.Case
  use ExPng.Constants

  alias ExPng.{Chunks.Header, Image, Pixel}

  describe "round trip" do
    test "for grayscale images" do
      for file <- Path.wildcard("test/png_suite/basic/basn0g*.png") do
        {:ok, image} = Image.from_file(file)
        {:ok, _} = Image.to_file(image, "experiment.png")
        {:ok, read_image} = Image.from_file("experiment.png")
        assert image.pixels == read_image.pixels
        :ok = File.rm("experiment.png")
      end
    end

    test "for truecolor images" do
      for file <- Path.wildcard("test/png_suite/basic/basn2c*.png") do
        {:ok, image} = Image.from_file(file)
        {:ok, _} = Image.to_file(image, "experiment.png")
        {:ok, read_image} = Image.from_file("experiment.png")
        assert image.pixels == read_image.pixels
        :ok = File.rm("experiment.png")
      end
    end

    test "for paletted images" do
      for file <- Path.wildcard("test/png_suite/basic/basn3p*.png") do
        {:ok, image} = Image.from_file(file)
        {:ok, _} = Image.to_file(image, "experiment.png")
        {:ok, read_image} = Image.from_file("experiment.png")
        assert image.pixels == read_image.pixels
        :ok = File.rm("experiment.png")
      end
    end
  end

  describe "to_lines" do
    test "it returns the correct number of lines for the image" do
      for file <- Path.wildcard("test/png_suite/basic/*.png") do
        {:ok, image} = Image.from_file(file)
        assert length(image.pixels) == image.raw_data.header_chunk.height
      end
    end
  end

  describe ".to_raw_data" do
    test "it creates the proper header chunk" do
      with {:ok, image} <- Image.from_file("test/png_suite/basic/basn0g01.png"),
           {:ok, raw_data} <- Image.to_raw_data(image) do
        header = raw_data.header_chunk
        assert header.width == 32
        assert header.height == 32
        assert header.bit_depth == 8
        assert header.color_type == @truecolor
        assert header.compression == 0
        assert header.filter == 0
        assert header.interlace == 0
      else
        _ -> assert false
      end
    end

    test "it creates the proper data chunk" do
      with {:ok, image} <- Image.from_file("test/png_suite/basic/basn0g01.png"),
           {:ok, raw_data} <- Image.to_raw_data(image) do
        [data | _] = raw_data.data_chunks
        assert <<0, 255, 255, 255, _::binary>> = data.data

        assert <<0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0, 32, 0, 0, 0, 32, _::binary>> =
                 Header.to_bytes(raw_data.header_chunk)
      else
        _ -> assert false
      end
    end
  end

  describe "drawing" do
    test "it uses Access behaviour to set/find/erase pixels" do
      image = Image.new(10, 10)
      assert Image.at(image, [2, 3]) == Pixel.white()
      image = Image.draw(image, [2, 3], Pixel.black())
      assert Image.at(image, [2, 3]) == Pixel.black()
      image = Image.clear(image, [2, 3])
      assert Image.at(image, [2, 3]) == Pixel.white()
    end

    test "erase will clear the image" do
      image = Image.new(10, 10)
      clean_pixels = image.pixels

      image = Image.line(image, 0, 0, 5, 4)
      refute image.pixels == clean_pixels

      image = Image.erase(image)

      assert image.pixels == clean_pixels
    end

    test "it draws a horizontal line" do
      image = Image.new(10, 10)
      image = Image.line(image, 0, 5, 9, 5)
      {:ok, reference} = Image.from_file("test/png_suite/drawing/horizontal.png")

      assert image.pixels == reference.pixels
    end

    test "it draws a vertical line" do
      image = Image.new(10, 10)
      image = Image.line(image, 3, 0, 3, 9)
      {:ok, reference} = Image.from_file("test/png_suite/drawing/vertical.png")

      assert image.pixels == reference.pixels
    end

    test "it draws a horizontal line with slope of 1" do
      image = Image.new(10, 10)
      image = Image.line(image, 0, 0, 9, 9)
      {:ok, reference} = Image.from_file("test/png_suite/drawing/diagonal.png")

      assert image.pixels == reference.pixels
    end

    test "it draws an anti-aliased diagonal line" do
      image = Image.new(10, 10)
      image = Image.line(image, 0, 2, 9, 8)
      {:ok, reference} = Image.from_file("test/png_suite/drawing/slope.png")

      assert image.pixels == reference.pixels
    end
  end
end
