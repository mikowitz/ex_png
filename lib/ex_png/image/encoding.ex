defmodule ExPng.Image.Encoding do
  @moduledoc """
  Utility module containing functtions necessary to encode an `ExPng.Image`
  back into a PNG file.
  """

  use ExPng.Constants

  import ExPng.Utilities, only: [reduce_to_binary: 1]

  alias ExPng.Chunks.{End, Header, ImageData, Palette}
  alias ExPng.{Image, Image.Adam7, Pixel, RawData}

  def to_raw_data(%Image{} = image, encoding_options \\ []) do
    header = build_header(image, encoding_options)
    filter_type = Keyword.get(encoding_options, :filter, @filter_up)
    interlaced = Keyword.get(encoding_options, :interlace, false)
    palette = Image.unique_pixels(image)
    to_raw_data(image, header, palette, filter_type, interlaced)
  end

  def to_raw_data(image, header, palette, filter_type, true) do
    image_data =
      image
      |> Adam7.decompose_into_sub_images()
      |> Enum.map(fn sub_image -> ImageData.from_pixels(sub_image, header, filter_type, palette) end)
      |> Enum.map(fn %ImageData{data: data} -> data end)
      |> Enum.reject(&is_nil/1)
      |> reduce_to_binary()

    raw_data =
      %RawData{
        header_chunk: header,
        data_chunk: %ImageData{data: image_data},
        end_chunk: %End{}
      }

    raw_data = case header.color_mode do
      @indexed ->
        %{raw_data |
          palette_chunk: %Palette{palette: palette}
        }
      _ -> raw_data
    end

    {:ok, raw_data}
  end

  def to_raw_data(image, header, palette, filter_type, false) do
    image_data_chunk = ImageData.from_pixels(image, header, filter_type, palette)
    raw_data =
      %RawData{
        header_chunk: header,
        data_chunk: image_data_chunk,
        end_chunk: %End{}
      }

    raw_data = case header.color_mode do
      @indexed ->
        %{raw_data |
          palette_chunk: %Palette{palette: palette}
        }
      _ -> raw_data
    end

    {:ok, raw_data}
  end

  defp build_header(%Image{} = image, encoding_options) do
    interlace = case Keyword.get(encoding_options, :interlace, false) do
      true -> 1
      false -> 0
    end
    {bit_depth, color_mode} = bit_depth_and_color_mode(image)
    %Header{
      width: image.width,
      height: image.height,
      bit_depth: bit_depth,
      color_mode: color_mode,
      compression: 0,
      filter: 0,
      interlace: interlace
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
