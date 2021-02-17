defmodule ExPng.Image.Encoding do
  @moduledoc """
  Utility module containing functtions necessary to encode an `ExPng.Image`
  back into a PNG file.
  """

  use ExPng.Constants

  alias ExPng.Chunks.{End, Header, ImageData}
  alias ExPng.{Image, Pixel, RawData}

  def to_raw_data(%Image{} = image, encoding_options \\ []) do
    header = build_header(image)
    filter_type = Keyword.get(encoding_options, :filter, @filter_none)
    {image_data_chunk, palette} = ImageData.from_pixels(image, header, filter_type)

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
    pixels = Image.unique_pixels(image)
    case black_and_white?(pixels) do
      true -> {1, @grayscale}
      false ->
        case {indexable?(pixels), opaque?(pixels), grayscale?(pixels)} do
          {_, true, true} -> {8, @grayscale}
          {_, false, true} -> {8, @grayscale_alpha}
          {true, _, _} -> {indexed_bit_depth(pixels), @indexed}
          {_, true, false} -> {8, @truecolor}
          {_, false, false} -> {8, @truecolor_alpha}
        end
    end
  end

  defp indexed_bit_depth(pixels) do
    case length(pixels) do
      i when i <= 2 -> 1
      i when i <= 4 -> 2
      i when i <= 16 -> 4
      i when i <= 256 -> 8
    end
  end

  defp indexable?(pixels) do
    length(pixels) <= 256
  end

  defp opaque?(pixels) do
    pixels
    |> Enum.all?(&Pixel.opaque?/1)
  end

  defp grayscale?(pixels) do
    pixels
    |> Enum.all?(&Pixel.grayscale?/1)
  end

  defp black_and_white?(pixels) do
    pixels
    |> Enum.all?(&Pixel.black_or_white?/1)
  end
end
