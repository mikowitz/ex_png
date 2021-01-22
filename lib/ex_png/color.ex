defmodule ExPng.Color do
  @moduledoc false

  use ExPng.Constants

  use Bitwise

  def pixel_bytesize(%ExPng.RawData{header_chunk: header}) do
    pixel_bytesize(header.color_type, header.bit_depth)
  end

  def pixel_bytesize(color_type, bit_depth \\ 8) do
    color_type
    |> pixel_bitsize(bit_depth)
    |> to_bytesize()
  end

  def line_bytesize(%ExPng.RawData{header_chunk: header}) do
    line_bytesize(header.color_type, header.bit_depth, header.width)
  end

  def line_bytesize(color_type, bit_depth, width) do
    color_type
    |> pixel_bitsize(bit_depth)
    |> Kernel.*(width)
    |> to_bytesize()
  end

  defp pixel_bitsize(color_type, bit_depth) do
    color_type
    |> channels_for_color_type()
    |> Kernel.*(bit_depth)
  end

  defp channels_for_color_type(@grayscale), do: 1
  defp channels_for_color_type(@truecolor), do: 3
  defp channels_for_color_type(@indexed), do: 1
  defp channels_for_color_type(@grayscale_alpha), do: 2
  defp channels_for_color_type(@truecolor_alpha), do: 4

  defp to_bytesize(x) do
    x
    |> Kernel.+(7)
    |> Bitwise.>>>(3)
  end
end
