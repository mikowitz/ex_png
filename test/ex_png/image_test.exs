defmodule ExPng.ImageTest do
  use ExUnit.Case
  use ExPng.Constants

  alias ExPng.{Chunks.Header, Image}

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
end
