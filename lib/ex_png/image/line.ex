defmodule ExPng.Image.Line do
  @moduledoc """
  Provides functionality for appyling the appropriate filter to lines of
  a PNG image and converting them to lists of `ExPng.Pixel` structs.

  A line can have one of five filter types, one of which simply means no filter
  has been applied, and each slice of pixel data contains its true value. The
  other four filter types encode the pixel data as the differenc between its
  true value and a neighboring pixel or pixels, according to which filter type
  is chosen.

  For `filter_sub`, each slice of pixel data stores the difference between its
  true value and the pixel immediately to its left (for theleftmost pixel in a
  line, it stores its full value in place.

  For `filter_up`, each slice stores the difference between its true value and
  the pixel immediately above it.

  For `filter_average`, each slice stores the difference between its true value
  and the average of the pixel slices to its left and above it

  With `filter_paeth`, the slice stores the difference betweens its true value
  and the value of the pixel to its left, above it, or the pixel to its
  "north-west", whichever of these three is closest to its true value.


  By doing this, it makes the total image data able to be compressed
  more during encoding, reducing total image size when writing to a PNG file.

  `ExPng` can decode PNG files using any type of filtering, but currently
  encodes all data using `filter_none`.
  """
  use Bitwise
  use ExPng.Constants

  alias ExPng.Pixel


  @type t :: %__MODULE__{
    filter_type: ExPng.filter(),
    data: binary()
  }
  defstruct [:filter_type, :data]

  @doc """
  Returns a `Line` struct defining the raw data of the line, and the filter
  type applied to it.
  """
  @spec new(ExPng.filter(), binary) :: __MODULE__.t
  def new(filter_type, data) do
    %__MODULE__{filter_type: filter_type, data: data}
  end

  @doc """
  Parses a de-filtered line of pixel data into a list of `ExPng.Pixel` structs
  based on the bit depth and color mode of the image. For images that use the
  `t:ExPng.indexed/0` color mode, the image's `ExPng.Chunks.Palette` data is passed
  as an optional 4th argument.

  In the code below, in the call to `new/2`, 0 represents the `t:ExPng.filter_none/0`
  filter type. In the call to `to_pixels/3`, 1 is the bit depth of the line --
  each piece of a pixel's data is encoded in a single bit -- and 0 is the
  reperesentation of the `t:ExPng.grayscale/0` color mode.

      iex> line = ExPng.Image.Line.new(0, <<21>>)
      iex> ExPng.Image.Line.to_pixels(line, 1, 0)
      [
        ExPng.Pixel.black(), ExPng.Pixel.black(),
        ExPng.Pixel.black(), ExPng.Pixel.white(),
        ExPng.Pixel.black(), ExPng.Pixel.white(),
        ExPng.Pixel.black(), ExPng.Pixel.white()
      ]


  Here, in the call to `to_pixels/3`, 8 shows that each part of a pixel's
  definition -- the red, green, and blue values -- is stored in 8 bits, or 1 byte,
  and the 2 is the code for the `t:ExPng.truecolor/0` color mode.

      iex> line = ExPng.Image.Line.new(0, <<100, 100, 200, 30, 42, 89>>)
      iex> ExPng.Image.Line.to_pixels(line, 8, 2)
      [
        ExPng.Pixel.rgb(100, 100, 200),
        ExPng.Pixel.rgb(30, 42, 89)
      ]

  """
  @spec to_pixels(__MODULE__.t, ExPng.bit_depth, ExPng.color_mode, ExPng.Chunks.Palette.t | nil) :: [ExPng.Pixel.t, ...]
  def to_pixels(line, bit_depth, color_mode, palette \\ nil)

  def to_pixels(%__MODULE__{data: data}, 1, @grayscale, _) do
    for <<x::1 <- data>>, do: Pixel.grayscale(x * 255)
  end

  def to_pixels(%__MODULE__{data: data}, 2, @grayscale, _) do
    for <<x::2 <- data>>, do: Pixel.grayscale(x * 85)
  end

  def to_pixels(%__MODULE__{data: data}, 4, @grayscale, _) do
    for <<x::4 <- data>>, do: Pixel.grayscale(x * 17)
  end

  def to_pixels(%__MODULE__{data: data}, 8, @grayscale, _) do
    for <<x::8 <- data>>, do: Pixel.grayscale(x)
  end

  def to_pixels(%__MODULE__{data: data}, 16, @grayscale, _) do
    for <<x, _ <- data>>, do: Pixel.grayscale(x)
  end

  def to_pixels(%__MODULE__{data: data}, 8, @truecolor, _) do
    for <<r, g, b <- data>>, do: Pixel.rgb(r, g, b)
  end

  def to_pixels(%__MODULE__{data: data}, 16, @truecolor, _) do
    for <<r, _, g, _, b, _ <- data>>, do: Pixel.rgb(r, g, b)
  end

  def to_pixels(%__MODULE__{data: data}, depth, @indexed, palette) do
    for <<x::size(depth) <- data>>, do: Enum.at(palette.palette, x)
  end

  def to_pixels(%__MODULE__{data: data}, 8, @grayscale_alpha, _) do
    for <<x, a <- data>>, do: Pixel.grayscale(x, a)
  end

  def to_pixels(%__MODULE__{data: data}, 16, @grayscale_alpha, _) do
    for <<x, _, a, _ <- data>>, do: Pixel.grayscale(x, a)
  end

  def to_pixels(%__MODULE__{data: data}, 8, @truecolor_alpha, _) do
    for <<r, g, b, a <- data>>, do: Pixel.rgba(r, g, b, a)
  end

  def to_pixels(%__MODULE__{data: data}, 16, @truecolor_alpha, _) do
    for <<r, _, g, _, b, _, a, _ <- data>>, do: Pixel.rgba(r, g, b, a)
  end

  @doc """
  Passes a line of pixel data through a filtering algorithm based on its filter
  type.
  """
  @spec filter_pass(__MODULE__.t, ExPng.bit_depth, __MODULE__.t | nil) :: __MODULE__.t
  def filter_pass(line, pixel_size, prev_line \\ nil)
  def filter_pass(%__MODULE__{filter_type: @filter_none} = line, _, _), do: line

  def filter_pass(%__MODULE__{filter_type: @filter_sub, data: data} = line, pixel_size, _) do
    [base | chunks] = for <<pixel::bytes-size(pixel_size) <- data>>, do: pixel

    filtered =
      Enum.reduce(chunks, [base], fn chunk, [prev | _] = acc ->
        new =
          Enum.reduce(0..(pixel_size - 1), <<>>, fn i, acc ->
            <<_::bytes-size(i), bit, _::binary>> = chunk
            <<_::bytes-size(i), a, _::binary>> = prev
            acc <> <<bit + a &&& 0xFF>>
          end)

        [new | acc]
      end)
      # this handles the reversal...something something fold direction...
      |> Enum.reduce(&Kernel.<>/2)

    %{line | data: filtered}
  end

  def filter_pass(%__MODULE__{filter_type: @filter_up, data: data} = line, pixel_size, nil) do
    prev_data = build_pad_for_filter(byte_size(data))
    filter_pass(line, pixel_size, prev_data)
  end

  def filter_pass(%__MODULE__{filter_type: @filter_up} = line, pixel_size, %__MODULE__{data: prev_data}) do
    filter_pass(line, pixel_size, prev_data)
  end

  def filter_pass(%__MODULE__{filter_type: @filter_up, data: data} = line, _pixel_size, prev_data) do
    filtered =
      Enum.reduce(0..(byte_size(data) - 1), <<>>, fn i, acc ->
        <<_::bytes-size(i), bit, _::binary>> = data
        <<_::bytes-size(i), b, _::binary>> = prev_data
        acc <> <<bit + b &&& 0xFF>>
      end)

    %{line | data: filtered}
  end

  def filter_pass(%__MODULE__{filter_type: @filter_average, data: data} = line, pixel_size, nil) do
    prev_data = build_pad_for_filter(byte_size(data))
    filter_pass(line, pixel_size, prev_data)
  end

  def filter_pass(%__MODULE__{filter_type: @filter_average} = line, pixel_size, %__MODULE__{data: prev_data}) do
    filter_pass(line, pixel_size, prev_data)
  end

  def filter_pass(%__MODULE__{filter_type: @filter_average, data: data} = line, pixel_size, prev_data) do
    pad = build_pad_for_filter(pixel_size)
    data = for <<pixel::bytes-size(pixel_size) <- data>>, do: pixel
    prev_line = for <<pixel::bytes-size(pixel_size) <- prev_data>>, do: pixel

    x =
      Enum.reduce(Enum.with_index(data), [pad], fn {byte, i}, [prev | _] = acc ->
        prev_line = Enum.at(prev_line, i)

        filtered_byte =
          Enum.reduce(0..(pixel_size - 1), <<>>, fn j, acc ->
            <<_::bytes-size(j), bit, _::binary>> = byte
            <<_::bytes-size(j), a, _::binary>> = prev
            <<_::bytes-size(j), b, _::binary>> = prev_line
            avg = (a + b) >>> 1
            acc <> <<avg + bit &&& 0xFF>>
          end)

        [filtered_byte | acc]
      end)
      |> Enum.reverse()
      |> Enum.drop(1)
      |> Enum.reduce(<<>>, fn c, acc ->
        acc <> c
      end)

    %{line | data: x}
  end

  def filter_pass(%__MODULE__{filter_type: @filter_paeth, data: data} = line, pixel_size, nil) do
    prev_data = build_pad_for_filter(byte_size(data))
    filter_pass(line, pixel_size, prev_data)
  end

  def filter_pass(%__MODULE__{filter_type: @filter_paeth} = line, pixel_size, %__MODULE__{data: prev_data}) do
    filter_pass(line, pixel_size, prev_data)
  end

  def filter_pass(%__MODULE__{filter_type: @filter_paeth, data: data} = line, pixel_size, prev_data) do
    pad = build_pad_for_filter(pixel_size)
    data = for <<pixel::bytes-size(pixel_size) <- data>>, do: pixel
    prev_line = for <<pixel::bytes-size(pixel_size) <- prev_data>>, do: pixel

    x =
      Enum.chunk_every([pad|prev_line], 2, 1, :discard)
      |> Enum.zip(data)
      |> Enum.reduce([pad], fn {[c_byte, b_byte], byte}, [a_byte | _] = acc ->

        filtered_byte =
          Enum.reduce(0..(pixel_size - 1), <<>>, fn j, acc ->
            <<_::bytes-size(j), x, _::binary>> = byte
            <<_::bytes-size(j), a, _::binary>> = a_byte
            <<_::bytes-size(j), b, _::binary>> = b_byte
            <<_::bytes-size(j), c, _::binary>> = c_byte
            delta = calculate_paeth_delta(a, b, c)
            acc <> <<delta + x &&& 0xFF>>
          end)

        [filtered_byte | acc]
      end)
      |> Enum.reverse()
      |> Enum.drop(1)
      |> Enum.reduce(<<>>, fn c, acc -> acc <> c end)

    %{line | data: x}
  end

  defp calculate_paeth_delta(a, b, c) do
    p = a + b - c
    pa = abs(p - a)
    pb = abs(p - b)
    pc = abs(p - c)

    cond do
      pa <= pb && pa <= pc -> a
      pb <= pc -> b
      true -> c
    end
  end

  defp build_pad_for_filter(pixel_size) do
    Stream.cycle([<<0>>])
    |> Enum.take(pixel_size)
    |> Enum.reduce(&Kernel.<>/2)
  end
end
