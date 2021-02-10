defmodule ExPng.Image.Decoding do
  @moduledoc """
  Utility module containing functions necessary for decoding a PNG image file
  into an `ExPng.Image`.
  """

  use ExPng.Constants

  alias ExPng.{Color, Image, Image.Adam7, Image.Line, RawData}

  def from_raw_data(%ExPng.RawData{header_chunk: %{interlace: 1}} = data) do
    %{width: width, height: height} = data.header_chunk


    image = Image.new(width, height)
    image =
      data
      |> Adam7.extract_sub_images()
      |> Adam7.compose_sub_images(image)

    %{image | raw_data: data}
  end
  def from_raw_data(%ExPng.RawData{} = data) do
    image =
      data
      |> build_lines()
      |> filter_pass()

    pixels =
      image.lines
      |> Enum.map(fn line ->
        Line.to_pixels(
          line,
          image.header_chunk.bit_depth,
          image.header_chunk.color_mode,
          image.palette_chunk
        ) |> Enum.take(data.header_chunk.width)
      end)

    %Image{
      pixels: pixels,
      raw_data: image,
      height: length(pixels),
      width: length(Enum.at(pixels, 0))
    }
  end

  def build_lines(%ExPng.RawData{data_chunk: data} = image) do
    with line_size <- Color.line_bytesize(image) do
      lines =
        for <<f, line::bytes-size(line_size) <- data.data>> do
          Line.new(f, line)
        end
      %{image | lines: lines}
    end
  end

  def filter_pass(lines, pixel_size) do
    Enum.reduce(lines, [nil], fn line, [prev | _] = acc ->
      new_line = Line.filter_pass(line, pixel_size, prev)
      [new_line | acc]
    end)
    |> Enum.reverse()
    |> Enum.drop(1)
  end

  def filter_pass(%RawData{lines: lines} = image) do
    lines =
      Enum.reduce(lines, [nil], fn line, [prev | _] = acc ->
        new_line = Line.filter_pass(line, Color.pixel_bytesize(image), prev)
        [new_line | acc]
      end)
      |> Enum.reverse()
      |> Enum.drop(1)

    %{image | lines: lines}
  end
end
