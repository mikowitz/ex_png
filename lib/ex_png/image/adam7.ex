defmodule ExPng.Image.Adam7 do
  @moduledoc false

  use Bitwise
  alias ExPng.{Color, Image, Image.Decoding, Image.Line, RawData}

  @pass_shifts_and_offsets [
    [3, 0, 3, 0],
    [3, 4, 3, 0],
    [2, 0, 3, 4],
    [2, 2, 2, 0],
    [1, 0, 2, 2],
    [1, 1, 1, 0],
    [0, 0, 1, 1],
  ]

  def pass_sizes(width, height) do
    for i <- 0..6 do
      pass_size(i, width, height)
    end
  end

  def extract_sub_images(%RawData{} = raw_data) do
    data = raw_data.data_chunk
    palette = raw_data.palette_chunk
    %{
      width: width,
      height: height,
      bit_depth: bit_depth,
      color_mode: color_mode
    } = raw_data.header_chunk
    passes = pass_sizes(width, height)

    {_, lines, _} = Enum.reduce(passes, {0, [], data.data}, fn [w, h], {pos, lines, data} ->
      line_length = Color.line_bytesize(color_mode, bit_depth, w)
      pixel_size = Color.pixel_bytesize(color_mode, bit_depth)

      if w * h > 0 do
        {pos, pass_lines, data} = Enum.reduce(1..h, {pos, [], data}, fn _, {pos, lines, data} ->
          <<f, line::bytes-size(line_length), data::binary>> = data
          line = Line.new(f, line)
          {pos + line_length + 1, [line|lines], data}
        end)
        pixels =
          pass_lines
          |> Enum.reverse()
          |> Decoding.filter_pass(pixel_size)
          |> Enum.map(& Line.to_pixels(&1, bit_depth, color_mode, palette) |> Enum.take(w))
        {pos, [pixels|lines], data}
      else
        {pos, lines, data}
      end
    end)
    Enum.reverse(lines)
    |> Enum.map(& Image.new(&1))
  end

  def compose_sub_images(sub_images, image) do
    sub_images
    |> Enum.with_index()
    |> Enum.reduce(image, fn {sub_image, pass}, image ->
      [x_shift, x_offset, y_shift, y_offset] = Enum.at(@pass_shifts_and_offsets, pass)
      height = sub_image.height
      width = sub_image.width
      coords = for x <- 0..(width-1), y <- 0..(height-1), do: {x, y}
      Enum.reduce(coords, image, fn {x, y}, image ->
        new_x = (x <<< x_shift) ||| x_offset
        new_y = (y <<< y_shift) ||| y_offset
        color = Image.at(sub_image, {x, y})
        Image.draw(image, {new_x, new_y}, color)
      end)
    end)
  end

  defp pass_size(pass, width, height) do
    [x_shift, x_offset, y_shift, y_offset] = Enum.at(@pass_shifts_and_offsets, pass)
    [
      (width  - x_offset + (1 <<< x_shift) - 1) >>> x_shift,
      (height - y_offset + (1 <<< y_shift) - 1) >>> y_shift
    ]
  end
end
