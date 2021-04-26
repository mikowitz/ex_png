defmodule ExPng.ImageTest do
  use ExUnit.Case
  use ExPng.Constants

  alias ExPng.{Color, Image}

  describe "round trip" do
    test "for non-interlaced images" do
      for file <- Path.wildcard("test/png_suite/basic/basn*.png") do
        assert_round_trip(file)
      end
    end

    test "for interlaced images" do
      for file <- Path.wildcard("test/png_suite/basic/basi*.png") do
        assert_round_trip(file)
      end
    end

    test "for images with different levels of compression" do
      for file <- Path.wildcard("test/png_suite/compression/*.png") do
        assert_round_trip(file)
      end
    end

    test "for images with different types of filtering" do
      for file <- Path.wildcard("test/png_suite/filtering/*.png") do
        assert_round_trip(file)
      end
    end

    test "for images with irregular sizes" do
      for file <- Path.wildcard("test/png_suite/sizes/*.png") do
        assert_round_trip(file)
      end
    end

    test "for images with different transparency settings" do
      for file <- Path.wildcard("test/png_suite/transparency/*.png") do
        assert_round_trip(file)
      end
    end
  end

  describe "transparency" do
    test "it maps onto the palette correctly" do
      {:ok, image} = Image.from_file("test/png_suite/transparency/tm3n3p02.png")

      assert image.raw_data.palette_chunk.palette == [
               <<0, 0, 255, 0>>,
               <<0, 0, 255, 85>>,
               <<0, 0, 255, 170>>,
               <<0, 0, 255, 255>>
             ]

      assert Image.at(image, {0, 0}) == <<0, 0, 255, 0>>
      assert Image.at(image, {31, 0}) == <<0, 0, 255, 85>>
      assert Image.at(image, {0, 31}) == <<0, 0, 255, 170>>
      assert Image.at(image, {31, 31}) == <<0, 0, 255, 255>>
    end

    test "it sets the target pixel correctly for a grayscale image" do
      {:ok, image} = Image.from_file("test/png_suite/transparency/tbbn0g04.png")

      assert image.raw_data.transparency_chunk.transparency == <<255, 255, 255>>

      assert Image.at(image, {0, 0}) == <<255, 255, 255, 0>>
    end

    test "it sets the target pixel correctly for a truecolor image" do
      {:ok, image} = Image.from_file("test/png_suite/transparency/tbbn2c16.png")

      assert image.raw_data.transparency_chunk.transparency == <<255, 255, 255>>

      assert Image.at(image, {0, 0}) == <<255, 255, 255, 0>>
    end
  end

  describe "drawing" do
    test "it uses Access behaviour to set/find/erase pixels" do
      image = Image.new(10, 10)
      assert Image.at(image, {2, 3}) == Color.white()
      image = Image.draw(image, {2, 3}, Color.black())
      assert Image.at(image, {2, 3}) == Color.black()
      image = Image.clear(image, {2, 3})
      assert Image.at(image, {2, 3}) == Color.white()
    end

    test "erase will clear the image" do
      image = Image.new(10, 10)
      clean_pixels = image.pixels

      image = Image.line(image, {0, 0}, {5, 4})
      refute image.pixels == clean_pixels

      image = Image.erase(image)

      assert image.pixels == clean_pixels
    end

    test "it draws a horizontal line" do
      image = Image.new(10, 10)
      image = Image.line(image, {0, 5}, {9, 5})
      {:ok, reference} = Image.from_file("test/png_suite/drawing/horizontal.png")

      assert image.pixels == reference.pixels
    end

    test "it draws a vertical line" do
      image = Image.new(10, 10)
      image = Image.line(image, {3, 0}, {3, 9})
      {:ok, reference} = Image.from_file("test/png_suite/drawing/vertical.png")

      assert image.pixels == reference.pixels
    end

    test "it draws a horizontal line with slope of 1" do
      image = Image.new(10, 10)
      image = Image.line(image, {0, 0}, {9, 9})
      {:ok, reference} = Image.from_file("test/png_suite/drawing/diagonal.png")

      assert image.pixels == reference.pixels
    end

    test "it draws an anti-aliased diagonal line" do
      image = Image.new(10, 10)
      image = Image.line(image, {0, 2}, {9, 8})
      {:ok, reference} = Image.from_file("test/png_suite/drawing/slope.png")

      assert image.pixels == reference.pixels
    end
  end

  describe "inspect" do
    test "it returns the correct terminal representation of the image" do
      image = Image.new(2, 2)

      assert inspect(image) ==
               """
               0xffffffff 0xffffffff
               0xffffffff 0xffffffff
               """
               |> String.trim()
    end
  end

  defp assert_round_trip(filename) do
    {:ok, image} = Image.from_file(filename)

    for filter <- [@filter_none, @filter_sub, @filter_up, @filter_average, @filter_paeth] do
      for interlace <- [true, false] do
        {:ok, data} = Image.to_binary(image, filter: filter, interlace: interlace)
        {:ok, read_image} = Image.from_binary(data)
        assert image.pixels == read_image.pixels
      end
    end

  end
end
