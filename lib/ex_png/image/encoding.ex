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
      bit_depth: calculate_bit_depth(image),
      color_type: calculate_color_type(image),
      compression: 0,
      filter: 0,
      interlace: 0
    }
  end

  def calculate_bit_depth(_image), do: 8
  def calculate_color_type(_image), do: @truecolor_alpha
end
