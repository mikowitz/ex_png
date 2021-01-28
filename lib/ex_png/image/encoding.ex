defmodule ExPng.Image.Encoding do
  @moduledoc false

  use ExPng.Constants

  alias ExPng.Chunks.{End, Header, ImageData}
  alias ExPng.{Image, RawData}

  def to_raw_data(%Image{} = image) do
    header = build_header(image)
    image_data_chunk = ImageData.from_pixels(image.pixels)

    {
      :ok,
      %RawData{
        header_chunk: header,
        data_chunks: [image_data_chunk],
        end_chunk: %End{}
      }
    }
  end

  defp build_header(%Image{} = image) do
    %Header{
      width: image.width,
      height: image.height,
      bit_depth: 8,
      color_type: @truecolor_alpha,
      compression: 0,
      filter: 0,
      interlace: 0
    }
  end
end
