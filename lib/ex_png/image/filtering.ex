defmodule ExPng.Image.Filtering do
  @moduledoc """
  This module contains code for filtering and defiltering lines of bytestring
  image data
  """

  use Bitwise
  use ExPng.Constants

  import ExPng.Utilities, only: [reduce_to_binary: 1]

  @type filtered_line :: {ExPng.filter, binary}

  @doc """
  Passes a line of filtered pixel data through a filtering algorithm based on its filter type, and returns the unfiltered original data.
  """
  @spec unfilter(filtered_line, ExPng.bit_depth, filtered_line | binary | nil) :: binary
  def unfilter(line, pixel_size, prev_line \\ nil)
  def unfilter({@filter_none, line}, _, _), do: line

  def unfilter({@filter_sub, data}, pixel_size, _) do
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

    # %{line | data: filtered}
    filtered
  end

  def unfilter({@filter_up, data} = line, pixel_size, nil) do
    prev_data = build_pad_for_filter(byte_size(data))
    unfilter(line, pixel_size, prev_data)
  end

  def unfilter({@filter_up, _} = line, pixel_size, {_, prev_data}) do
    unfilter(line, pixel_size, prev_data)
  end

  def unfilter({@filter_up, data}, _pixel_size, prev_data) do
    Enum.reduce(0..(byte_size(data) - 1), <<>>, fn i, acc ->
      <<_::bytes-size(i), bit, _::binary>> = data
      <<_::bytes-size(i), b, _::binary>> = prev_data
      acc <> <<bit + b &&& 0xFF>>
    end)
  end

  def unfilter({@filter_average, data} = line, pixel_size, nil) do
    prev_data = build_pad_for_filter(byte_size(data))
    unfilter(line, pixel_size, prev_data)
  end

  def unfilter({@filter_average, _} = line, pixel_size, {_, prev_data}) do
    unfilter(line, pixel_size, prev_data)
  end

  def unfilter({@filter_average, data}, pixel_size, prev_data) do
    pad = build_pad_for_filter(pixel_size)
    data = for <<pixel::bytes-size(pixel_size) <- data>>, do: pixel
    prev_line = for <<pixel::bytes-size(pixel_size) <- prev_data>>, do: pixel

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
    |> reduce_to_binary()
  end

  def unfilter({@filter_paeth, data} = line, pixel_size, nil) do
    prev_data = build_pad_for_filter(byte_size(data))
    unfilter(line, pixel_size, prev_data)
  end

  def unfilter({@filter_paeth, _} = line, pixel_size, {_, prev_data}) do
    unfilter(line, pixel_size, prev_data)
  end

  def unfilter({@filter_paeth, data}, pixel_size, prev_data) do
    pad = build_pad_for_filter(pixel_size)
    data = for <<pixel::bytes-size(pixel_size) <- data>>, do: pixel
    prev_line = for <<pixel::bytes-size(pixel_size) <- prev_data>>, do: pixel

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
    |> reduce_to_binary()
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
