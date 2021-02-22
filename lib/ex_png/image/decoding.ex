defmodule ExPng.Image.Decoding do
  @moduledoc """
  Utility module containing functions necessary for decoding a PNG image file
  into an `ExPng.Image`.
  """

  use ExPng.Constants

  alias ExPng.{Color, Image, Image.Adam7, Image.Filtering, Image.Pixelation, RawData}

  @doc """
  Converts a `RawData` struct into an `Image` struct.
  """
  @spec from_raw_data(RawData.t) :: Image.t
  def from_raw_data(%RawData{header_chunk: %{interlace: 1}} = data) do
    %{width: width, height: height} = data.header_chunk

    image = Image.new(width, height)
    image =
      data
      |> Adam7.extract_sub_images()
      |> Adam7.compose_sub_images(image)

    %{image | raw_data: data}
  end
  def from_raw_data(%RawData{} = data) do
    lines =
      data
      |> build_lines()
      |> unfilter(Color.pixel_bytesize(data))

    pixels =
      lines
      |> Enum.map(fn line ->
        Pixelation.to_pixels(
          line,
          data.header_chunk.bit_depth,
          data.header_chunk.color_mode,
          data.palette_chunk
        ) |> Enum.take(data.header_chunk.width)
      end)

    %Image{
      pixels: pixels,
      raw_data: data,
      height: length(pixels),
      width: length(Enum.at(pixels, 0))
    }
  end

  defp build_lines(%RawData{data_chunk: data} = image) do
    with line_size <- Color.line_bytesize(image) do
      for <<f, line::bytes-size(line_size) <- data.data>>, do: {f, line}
    end
  end

  def unfilter(lines, pixel_size) do
    Enum.reduce(lines, [nil], fn line, [prev | _] = acc ->
      new_line = Filtering.unfilter(line, pixel_size, prev)
      [new_line | acc]
    end)
    |> Enum.reverse()
    |> Enum.drop(1)
  end
end
