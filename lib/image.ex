defmodule ExPng.Image do
  alias ExPng.{Color, Image.Line}

  defstruct [
    :header,
    :data,
    :palette,
    :end,
    :ancillary_chunks,
    :lines,
    :pixels
  ]

  def from_chunks(header_chunk, chunks) do
    with {:ok, data_chunks, chunks} <- find_image_data(chunks),
         {:ok, end_chunk, chunks} <- find_end(chunks),
         {:ok, palette, chunks} <- find_palette(chunks, header_chunk)
    do
      {
        :ok,
        %__MODULE__{
          header: header_chunk,
          data: merge_data_chunks(data_chunks),
          palette: palette,
          end: end_chunk,
          ancillary_chunks: chunks
        }
      }
    else
      {:error, error} -> {:error, error}
    end
  end

  def to_ppm(%{pixels: pixels} = image) do
    {:ok, file} = File.open("test.ppm", [:write])
    IO.write(file, "P3\n")
    IO.write(file, "#{image.header.width} #{image.header.height}\n")
    IO.write(file, "255\n")
    Enum.each(pixels, fn line ->
      Enum.each(line, fn pixel ->
        IO.write(file, "#{pixel.r} #{pixel.g} #{pixel.b} ")
      end)
      IO.write(file, "\n")
    end)
    File.close(file)
  end

  def to_canvas(%__MODULE__{} = image) do
    image = image |> to_lines() |> filter_pass()

    pixels =
      image.lines
      |> Enum.map(fn line ->
        Line.to_pixels(line, image.header.bit_depth, image.header.color_type, image.palette)
      end)

    %{image | pixels: pixels}
  end

  def to_lines(%__MODULE__{data: data} = image) do
    with line_size <- Color.line_bytesize(image) do
      lines = do_to_lines(line_size, image.header.width, data.data, [])
      %{image | lines: lines}
    end
  end

  def filter_pass(%__MODULE__{lines: lines} = image) do
    lines = Enum.reduce(lines, [nil], fn line, [prev|_] = acc ->
      new_line = Line.filter_pass(line, Color.pixel_bytesize(image), prev)
      [new_line | acc]
    end)
    |> Enum.reverse()
    |> Enum.drop(1)
    %{image | lines: lines}
  end

  defp do_to_lines(_, _, <<>>, lines), do: Enum.reverse(lines)
  defp do_to_lines(line_size, image_width, data, lines) do
    case data do
      <<f, line::bytes-size(line_size), rest::binary>> ->
        new_line = %ExPng.Image.Line{
          filter_type: f,
          data: line,
          image_width: image_width,
        }
        do_to_lines(line_size, image_width, rest, [new_line|lines])
      _ -> {:error, "can't parse line"}
    end
  end

  defp find_image_data(chunks) do
    case Enum.split_with(chunks, &(&1.type == "IDAT")) do
      {[], _} -> {:error, "missing IDAT chunks"}
      {image_data, chunks} -> {:ok, image_data, chunks}
    end
  end

  defp find_end(chunks) do
    case Enum.find(chunks, &(&1.type == "IEND")) do
      nil -> {:error, "missing IEND chunk"}
      chunk -> {:ok, chunk, Enum.reject(chunks, fn c -> c == chunk end)}
    end
  end

  defp find_palette(chunks, %{color_type: color_type}) do
    case {Enum.find(chunks, &(&1.type == "PLTE")), color_type} do
      {nil, 3} -> {:error, "missing PLTE for color type 3"}
      {plt, ct} when not is_nil(plt) and ct in [0, 4] -> {:error, "PLTE present for grayscale image"}
      {plt, _} -> {:ok, plt, Enum.reject(chunks, fn c -> c == plt end)}
    end
  end

  defp merge_data_chunks(data_chunks) do
    data = Enum.reduce(data_chunks, <<>>, fn chunk, acc ->
      acc <> chunk.data
    end)
    %ExPng.Chunks.ImageData{data: data}
  end
end
