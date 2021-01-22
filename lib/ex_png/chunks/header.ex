defmodule ExPng.Chunks.Header do
  @moduledoc false

  defstruct [
    :width,
    :height,
    :bit_depth,
    :color_type,
    :compression,
    :filter,
    :interlace,
    type: "IHDR"
  ]

  def new("IHDR", <<w::32, h::32, bd, ct, cmp, fltr, intlc>> = data) do
    with {:ok, bit_depth} <- validate_bit_depth(bd),
         {:ok, color_type} <- validate_color_type(ct) do
      {
        :ok,
        %__MODULE__{
          width: w,
          height: h,
          bit_depth: bit_depth,
          color_type: color_type,
          compression: cmp,
          filter: fltr,
          interlace: intlc
        }
      }
    else
      {:error, _, _} -> {:error, "malformed IHDR", data}
    end
  end

  def to_bytes(%__MODULE__{} = header) do
    with {:ok, bit_depth} <- validate_bit_depth(header.bit_depth),
         {:ok, color_type} <- validate_color_type(header.color_type) do
      length = <<13::32>>
      type = <<73, 72, 68, 82>>

      data =
        <<header.width::32, header.height::32, bit_depth, color_type, header.compression,
          header.filter, header.interlace>>

      crc = :erlang.crc32([type, data])
      length <> type <> data <> <<crc::32>>
    else
      error -> error
    end
  end

  defp validate_bit_depth(bd) when bd in [1, 2, 4, 8, 16], do: {:ok, bd}
  defp validate_bit_depth(bd), do: {:error, "invalid bit depth", bd}

  defp validate_color_type(ct) when ct in [0, 2, 3, 4, 6], do: {:ok, ct}
  defp validate_color_type(ct), do: {:error, "invalid color type", ct}
end
