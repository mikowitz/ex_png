defmodule ExPng.Color do
  use Bitwise
  def pixel_bytesize(%ExPng.Image{header: header}) do
    pixel_bytesize(header.color_type, header.bit_depth)
  end
  def pixel_bytesize(color_type, bit_depth \\ 8) do
    color_type
    |> pixel_bitsize(bit_depth)
    |> Kernel.+(7)
    |> Bitwise.>>>(3)
  end

  def line_bytesize(%ExPng.Image{header: header}) do
    line_bytesize(header.color_type, header.bit_depth, header.width)
  end
  def line_bytesize(color_type, bit_depth, width) do
    color_type
    |> pixel_bitsize(bit_depth)
    |> Kernel.*(width)
    |> Kernel.+(7)
    |> Bitwise.>>>(3)
  end

  defp pixel_bitsize(color_type, bit_depth) do
    color_type
    |> channels_for_color_type()
    |> Kernel.*(bit_depth)
  end

  defp channels_for_color_type(0), do: 1
  defp channels_for_color_type(2), do: 3
  defp channels_for_color_type(3), do: 1
  defp channels_for_color_type(4), do: 2
  defp channels_for_color_type(6), do: 4
end
