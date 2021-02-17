defmodule ExPng.Chunks.ImageDataTest do
  use ExUnit.Case
  use ExPng.Constants

  alias ExPng.{Image, Pixel}
  alias ExPng.Chunks.{Header, ImageData}

  setup do
    image = %Image{
      pixels: [
        [Pixel.white(), Pixel.black()],
        [Pixel.rgba(100, 200, 100, 100), Pixel.rgb(100, 200, 255)]
      ]
    }
    {:ok, image: image}
  end

  describe "from_pixels" do
    test "grayscale, bit depth 1", context  do
      {image_data, _} = image_data_from_pixels(context.image, 1, @grayscale)
      assert image_data.data == <<0, 128, 0, 64>>
    end

    test "grayscale, bit depth 8", context do
      {image_data, _} = image_data_from_pixels(context.image, 8, @grayscale)
      assert image_data.data == <<0, 255, 0, 0, 100, 255>>
    end

    test "indexed, bit_depth 1", context do
      {image_data, palette} = image_data_from_pixels(context.image, 2, @indexed)
      assert image_data.data == <<0, 16, 0, 176>>
      assert palette.palette == [
        Pixel.white(),
        Pixel.black(),
        Pixel.rgba(100, 200, 100, 100),
        Pixel.rgb(100, 200, 255)
      ]
    end

    test "grayscale alpha, bit depth 8", context do
      {image_data, _} = image_data_from_pixels(context.image, 8, @grayscale_alpha)
      assert image_data.data == <<0, 255, 255, 0, 255, 0, 100, 100, 255, 255>>
    end

    test "truecolor alpha, bit depth 8", context do
      {image_data, _} = image_data_from_pixels(context.image, 8, @truecolor_alpha)
      assert image_data.data ==
        <<
          0, 255, 255, 255, 255, 0, 0, 0, 255,
          0, 100, 200, 100, 100, 100, 200, 255, 255
        >>
    end

    test "truecolor, bit depth 8, filter sub", context do
      {image_data, _} = image_data_from_pixels(context.image, 8, @truecolor, @filter_sub)
      assert image_data.data ==
        <<
          1, 255, 255, 255, 1, 1, 1,
          1, 100, 200, 100, 0, 0, 155
        >>
    end
  end

  defp image_data_from_pixels(image, bit_depth, color_mode, filter_type \\ @filter_none) do
    header = %Header{
      bit_depth: bit_depth,
      color_mode: color_mode
    }
    ImageData.from_pixels(image, header, filter_type)
  end
end
