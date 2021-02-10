defmodule ExPng.Image.Encoding do
  @moduledoc """
  Utility module containing functtions necessary to encode an `ExPng.Image`
  back into a PNG file.
  """

  use ExPng.Constants

  alias ExPng.Chunks.{End, Header, ImageData}
  alias ExPng.{Image, Pixel, RawData}

  def to_raw_data(%Image{} = image) do
    header = build_header(image)
    {image_data_chunk, palette} = ImageData.from_pixels(image, header)

    raw_data =
      %RawData{
        header_chunk: header,
        data_chunk: image_data_chunk,
        end_chunk: %End{}
      }

    raw_data = case header.color_mode do
      @indexed ->
        %{raw_data |
          palette_chunk: palette
        }
      _ -> raw_data
    end

    {:ok, raw_data}
  end

  defp build_header(%Image{} = image) do
    {bit_depth, color_mode} = bit_depth_and_color_mode(image)
    %Header{
      width: image.width,
      height: image.height,
      bit_depth: bit_depth,
      color_mode: color_mode,
      compression: 0,
      filter: 0,
      interlace: 0
    }
  end

  # 1. black and white
  # 2. grayscale (alpha)
  # 3. indexed
  # 4. truecolor (alpha)
  defp bit_depth_and_color_mode(%Image{} = image) do
    case black_and_white?(image) do
      true -> {1, @grayscale}
      false ->
        case {indexable?(image), opaque?(image), grayscale?(image)} do
          {_, true, true} -> {8, @grayscale}
          {_, false, true} -> {8, @grayscale_alpha}
          {true, _, _} -> {indexed_bit_depth(image), @indexed}
          {_, true, false} -> {8, @truecolor}
          {_, false, false} -> {8, @truecolor_alpha}
        end
    end
  end

  defp indexed_bit_depth(%Image{} = image) do
    case unique_pixel_count(image) do
      i when i <= 2 -> 1
      i when i <= 4 -> 2
      i when i <= 16 -> 4
      i when i <= 256 -> 8
    end
  end

  defp indexable?(%Image{} = image) do
    image
    |> unique_pixel_count()
    |> Kernel.<=(256)
  end

  defp unique_pixel_count(%Image{} = image) do
    image
    |> Image.unique_pixels()
    |> length()
  end

  defp opaque?(%Image{pixels: pixels}) do
    pixels
    |> List.flatten()
    |> Enum.all?(&Pixel.opaque?/1)
  end

  defp grayscale?(%Image{pixels: pixels}) do
    pixels
    |> List.flatten()
    |> Enum.all?(&Pixel.grayscale?/1)
  end

  defp black_and_white?(%Image{pixels: pixels}) do
    pixels
    |> List.flatten()
    |> Enum.all?(&Pixel.black_or_white?/1)
  end
end
