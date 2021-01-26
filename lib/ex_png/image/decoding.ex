defmodule ExPng.Image.Decoding do
  @moduledoc false

  use ExPng.Constants

  alias ExPng.{Chunks.ImageData, Color, Image, Image.Adam7, Image.Line, RawData}

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
      |> to_lines()
      |> filter_pass()

    pixels =
      image.lines
      |> Enum.map(fn line ->
        Line.to_pixels(
          line,
          image.header_chunk.bit_depth,
          image.header_chunk.color_type,
          image.palette_chunk
        )
      end)

    %Image{
      pixels: pixels,
      raw_data: image,
      height: length(pixels),
      width: length(Enum.at(pixels, 0))
    }
  end

  def to_lines(%ExPng.RawData{data_chunks: data} = image) do
    data = ImageData.merge(data)

    with line_size <- Color.line_bytesize(image) do
      lines = do_to_lines(line_size, data.data, [])
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

  defp do_to_lines(_, <<>>, lines), do: Enum.reverse(lines)

  defp do_to_lines(line_size, data, lines) do
    case data do
      <<f, line::bytes-size(line_size), rest::binary>> ->
        new_line = Line.new(f, line)
        do_to_lines(line_size, rest, [new_line | lines])

      _ ->
        {:error, "can't parse line"}
    end
  end
end
