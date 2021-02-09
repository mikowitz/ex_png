defmodule ExPng.Image.Encoding do
  @moduledoc """
  Utility module containing functtions necessary to encode an `ExPng.Image`
  back into a PNG file.
  """

  use ExPng.Constants

  alias ExPng.Chunks.{End, Header, ImageData}
  alias ExPng.{Image, Pixel, RawData}

  def to_raw_data(%Image{} = image, _encoding_options \\ []) do
    header = build_header(image)
    image_data_chunk = ImageData.from_pixels(image.pixels, header.color_mode, header.bit_depth)

    {
      :ok,
      %RawData{
        header_chunk: header,
        data_chunk: image_data_chunk,
        end_chunk: %End{}
      }
    }
  end

  defp build_header(%Image{} = image) do
    color_mode = determine_color_mode(image)
    bit_depth = determine_bit_depth(image)
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

  defp determine_color_mode(%Image{} = image) do
    case {grayscale?(image), opaque?(image)} do
      {true, true} -> @grayscale
      {true, false} -> @grayscale_alpha
      {false, true} -> @truecolor
      {false, false} -> @truecolor_alpha
    end
  end

  defp determine_bit_depth(%Image{} = image) do
    case black_and_white?(image) do
      true -> 1
      false -> 8
    end
  end

  defp black_and_white?(%Image{pixels: pixels}) do
    pixels
    |> List.flatten()
    |> Enum.all?(&Pixel.black_or_white?/1)
  end

  defp grayscale?(%Image{pixels: pixels}) do
    pixels
    |> List.flatten()
    |> Enum.all?(&Pixel.grayscale?/1)
  end

  defp opaque?(%Image{pixels: pixels}) do
    pixels
    |> List.flatten()
    |> Enum.all?(&Pixel.opaque?/1)
  end
end
