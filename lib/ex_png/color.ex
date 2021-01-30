defmodule ExPng.Color do
  @moduledoc false

  use ExPng.Constants

  use Bitwise

  def pixel_bytesize(%ExPng.RawData{header_chunk: header}) do
    pixel_bytesize(header.color_mode, header.bit_depth)
  end

  def pixel_bytesize(color_mode, bit_depth \\ 8) do
    color_mode
    |> pixel_bitsize(bit_depth)
    |> to_bytesize()
  end

  def line_bytesize(%ExPng.RawData{header_chunk: header}) do
    line_bytesize(header.color_mode, header.bit_depth, header.width)
  end

  def line_bytesize(color_mode, bit_depth, width) do
    color_mode
    |> pixel_bitsize(bit_depth)
    |> Kernel.*(width)
    |> to_bytesize()
  end

  defp pixel_bitsize(color_mode, bit_depth) do
    color_mode
    |> channels_for_color_mode()
    |> Kernel.*(bit_depth)
  end

  defp channels_for_color_mode(@grayscale), do: 1
  defp channels_for_color_mode(@truecolor), do: 3
  defp channels_for_color_mode(@indexed), do: 1
  defp channels_for_color_mode(@grayscale_alpha), do: 2
  defp channels_for_color_mode(@truecolor_alpha), do: 4

  defp to_bytesize(x) do
    x
    |> Kernel.+(7)
    |> Bitwise.>>>(3)
  end
end
