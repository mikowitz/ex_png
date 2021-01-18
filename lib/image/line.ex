defmodule ExPng.Image.Line do
  alias ExPng.Pixel
  use Bitwise

  defstruct [:filter_type, :data, :image_width]

  def to_pixels(line, bit_depth, color_type, palette \\ nil)
  def to_pixels(%__MODULE__{data: data}, 1, 0, _) do
    for <<x::1 <- data>> do
      case x do
        1 -> Pixel.white()
        0 -> Pixel.black()
      end
    end
  end

  def to_pixels(%__MODULE__{data: data}, 2, 0, _) do
    for <<x::2 <- data>>, do: Pixel.grayscale(x*85)
  end

  def to_pixels(%__MODULE__{data: data}, 4, 0, _) do
    for <<x::4 <- data>>, do: Pixel.grayscale(x*17)
  end

  def to_pixels(%__MODULE__{data: data}, 8, 0, _) do
    for <<x <- data>>, do: Pixel.grayscale(x)
  end

  def to_pixels(%__MODULE__{data: data}, 16, 0, _) do
    for <<x, _ <- data>>, do: Pixel.grayscale(x)
  end

  def to_pixels(%__MODULE__{data: data}, 8, 2, _) do
    for <<r, g, b <- data>>, do: Pixel.rgb(r, g, b)
  end

  def to_pixels(%__MODULE__{data: data}, 16, 2, _) do
    for <<r, _, g, _, b, _ <- data>>, do: Pixel.rgb(r, g, b)
  end

  def to_pixels(%__MODULE__{data: data}, depth, 3, palette) do
    for <<x::size(depth) <- data>>, do: Enum.at(palette.palette, x)
  end

  def to_pixels(%__MODULE__{data: data}, 8, 4, _) do
    for <<x, a <- data>>, do: Pixel.grayscale(x, a)
  end

  def to_pixels(%__MODULE__{data: data}, 16, 4, _) do
    for <<x, _, a, _ <- data>>, do: Pixel.grayscale(x, a)
  end

  def to_pixels(%__MODULE__{data: data}, 8, 6, _) do
    for <<r, g, b, a <- data>>, do: Pixel.rgba(r, g, b, a)
  end

  def to_pixels(%__MODULE__{data: data}, 16, 6, _) do
    for <<r, _, g, _, b, _, a, _ <- data>>, do: Pixel.rgba(r, g, b, a)
  end

  def filter_pass(line, pixel_size, prev_line \\ nil)
  def filter_pass(%__MODULE__{filter_type: 0} = line, _, _), do: line
  def filter_pass(%__MODULE__{filter_type: 1, data: data} = line, pixel_size, _) do
    [base|chunks] = for <<pixel::bytes-size(pixel_size) <- data>>, do: pixel
    filtered = Enum.reduce(chunks, [base], fn chunk, [prev|_] = acc ->
      new = Enum.reduce(0..(pixel_size-1), <<>>, fn i, acc ->
        <<_::bytes-size(i), bit, _::binary>> = chunk
        <<_::bytes-size(i), a, _::binary>> = prev
        acc <> <<(bit + a) &&& 0xff>>
      end)
      [new|acc]
    end)
    # this pipe reduction handles the reversal...somehow?
    |> Enum.reduce(&Kernel.<>/2)
    %{line | data: filtered}
  end
  def filter_pass(%__MODULE__{filter_type: 2, data: data} = line, _, %__MODULE__{data: prev_data}) do
    filtered = Enum.reduce(0..(byte_size(data)-1), <<>>, fn i, acc ->
      <<_::bytes-size(i), bit, _::binary>> = data
      <<_::bytes-size(i), b, _::binary>> = prev_data
      acc <> <<(bit + b) &&& 0xff>>
    end)
    %{line | data: filtered}
  end

  def filter_pass(%__MODULE__{filter_type: 3, data: data} = line, pixel_size, nil) do
    prev_data = Enum.reduce(1..byte_size(data), <<>>, fn _, acc -> acc <> <<0>> end)
    filter_pass(line, pixel_size, prev_data)
  end
  def filter_pass(%__MODULE__{filter_type: 3} = line, pixel_size, %__MODULE__{data: prev_data}) do
    filter_pass(line, pixel_size, prev_data)
  end
  def filter_pass(%__MODULE__{filter_type: 3, data: data} = line, pixel_size, prev_data) do
    pad = Enum.reduce(1..pixel_size, <<>>, fn _, acc -> acc <> <<0>> end)
    data = for <<pixel::bytes-size(pixel_size) <- data>>, do: pixel
    prev_line = for <<pixel::bytes-size(pixel_size) <- prev_data>>, do: pixel
    x = Enum.reduce(Enum.with_index(data), [pad], fn {byte, i}, [prev|_] = acc ->
      prev_line = Enum.at(prev_line, i)
      filtered_byte = Enum.reduce(0..(pixel_size-1), <<>>, fn j, acc ->
        <<_::bytes-size(j), bit, _::binary>> = byte
        <<_::bytes-size(j), a, _::binary>> = prev
        <<_::bytes-size(j), b, _::binary>> = prev_line
        avg = (a + b) >>> 1
        acc <> <<(avg + bit) &&& 0xff>>
      end)
      [filtered_byte|acc]
    end)
    |> Enum.reverse()
    |> Enum.drop(1)
    |> Enum.reduce(<<>>, fn c, acc ->
      acc <> c
    end)
    %{line | data: x}
  end

  def filter_pass(%__MODULE__{filter_type: 4, data: data} = line, pixel_size, nil) do
    prev_data = Enum.reduce(1..byte_size(data), <<>>, fn _, acc -> acc <> <<0>> end)
    filter_pass(line, pixel_size, prev_data)
  end
  def filter_pass(%__MODULE__{filter_type: 4} = line, pixel_size, %__MODULE__{data: prev_data}) do
    filter_pass(line, pixel_size, prev_data)
  end
  def filter_pass(%__MODULE__{filter_type: 4, data: data} = line, pixel_size, prev_data) do
    pad = Enum.reduce(1..pixel_size, <<>>, fn _, acc -> acc <> <<0>> end)
    data = for <<pixel::bytes-size(pixel_size) <- data>>, do: pixel
    prev_line = for <<pixel::bytes-size(pixel_size) <- prev_data>>, do: pixel
    x = Enum.reduce(Enum.with_index(data), [pad], fn {byte, i}, [a_byte|_] = acc ->
      b_byte = Enum.at(prev_line, i)
      c_byte = if i == 0, do: pad, else: Enum.at(prev_line, i-1)
      filtered_byte = Enum.reduce(0..(pixel_size-1), <<>>, fn j, acc ->
        <<_::bytes-size(j), x, _::binary>> = byte
        <<_::bytes-size(j), a, _::binary>> = a_byte
        <<_::bytes-size(j), b, _::binary>> = b_byte
        <<_::bytes-size(j), c, _::binary>> = c_byte
        p = a + b - c
        pa = abs(p - a)
        pb = abs(p - b)
        pc = abs(p - c)
        delta = cond do
          pa <= pb && pa <= pc -> a
          pb <= pc -> b
          true -> c
        end
        acc <> <<(delta + x) &&& 0xff>>
      end)
      [filtered_byte|acc]
    end)
    |> Enum.reverse()
    |> Enum.drop(1)
    |> Enum.reduce(<<>>, fn c, acc -> acc <> c end)
    %{line | data: x }
  end
end
