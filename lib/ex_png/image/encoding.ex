defmodule ExPng.Image.Encoding do
  @moduledoc """
  Utility module containing functtions necessary to encode an `ExPng.Image`
  back into a PNG file.
  """

  use ExPng.Constants

  alias ExPng.Chunks.{End, Header, ImageData}
  alias ExPng.{Image, RawData}

  def to_raw_data(%Image{} = image, _encoding_options \\ []) do
    header = build_header(image)
    image_data_chunk = ImageData.from_pixels(image.pixels)

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
    %Header{
      width: image.width,
      height: image.height,
      bit_depth: 8,
      color_mode: @truecolor_alpha,
      compression: 0,
      filter: 0,
      interlace: 0
    }
  end
end
