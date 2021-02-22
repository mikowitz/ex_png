defmodule ExPng.Image.Adam7 do
  @moduledoc false

  use Bitwise
  alias ExPng.{Color, Image, Image.Decoding, Image.Pixelation, RawData}

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
          line = {f, line}
          {pos + line_length + 1, [line|lines], data}
        end)
        pixels =
          pass_lines
          |> Enum.reverse()
          |> Decoding.unfilter(pixel_size)
          |> Enum.map(& Pixelation.to_pixels(&1, bit_depth, color_mode, palette) |> Enum.take(w))
        {pos, [pixels|lines], data}
      else
        {pos, [nil|lines], data}
      end
    end)
    Enum.reverse(lines)
    |> Enum.map(fn pixels ->
      case pixels do
        nil -> nil
        _ -> Image.new(pixels)
      end
    end)
  end

  def compose_sub_images(sub_images, image) do
    sub_images
    |> Enum.with_index()
    |> Enum.reduce(image, fn {sub_image, pass}, image ->
      merge_sub_image(sub_image, pass, image)
    end)
  end

  defp merge_sub_image(nil, _pass, image), do: image
  defp merge_sub_image(sub_image, pass, image) do
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
  end

  def decompose_into_sub_images(image) do
    for pass <- 0..6 do
      [x_shift, x_offset, y_shift, y_offset] = Enum.at(@pass_shifts_and_offsets, pass)
      ys = Stream.iterate(y_offset, & &1 + (1 <<< y_shift)) |> Enum.take_while(fn y -> y < image.height end)
      xs = Stream.iterate(x_offset, & &1 + (1 <<< x_shift)) |> Enum.take_while(fn x -> x < image.height end)
      [width, _height] = pass_size(pass, image.width, image.height)

      coords = for x <- xs, y <- ys, do: {x, y}
      pixels =
        coords
        |> Enum.sort_by(fn {x, y} -> [y, x] end)
        |> Enum.map(fn coord -> Image.at(image, coord) end)

      case length(pixels) do
        0 -> nil
        _ ->
          pixels
          |> Enum.chunk_every(width)
          |> Image.new
      end
    end
  end

  defp pass_size(pass, width, height) do
    [x_shift, x_offset, y_shift, y_offset] = Enum.at(@pass_shifts_and_offsets, pass)
    [
      (width  - x_offset + (1 <<< x_shift) - 1) >>> x_shift,
      (height - y_offset + (1 <<< y_shift) - 1) >>> y_shift
    ]
  end
end

      # def adam7_extract_pass(pass, canvas)
      #   x_shift, x_offset, y_shift, y_offset = adam7_multiplier_offset(pass)
      #   sm_pixels = []

      #   y_offset.step(canvas.height - 1, 1 << y_shift) do |y|
      #     x_offset.step(canvas.width - 1, 1 << x_shift) do |x|
      #       sm_pixels << canvas[x, y]
      #     end
      #   end

      #   new_canvas_args = adam7_pass_size(pass, canvas.width, canvas.height) + [sm_pixels]
      #   ChunkyPNG::Canvas.new(*new_canvas_args)
      # end
