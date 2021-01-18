defmodule ExPng.Chunks.Header do
  defstruct [
    :width, :height, :bit_depth, :color_type,
    :compression, :filter, :interlace,
    type: "IHDR"
  ]

  def new(<<w::32, h::32, bd, ct, cmp, fltr, intlc>> = data) do
    with {:ok, bit_depth} <- validate_bit_depth(bd),
         {:ok, color_type} <- validate_color_type(ct)
    do
      {
        :ok,
        %__MODULE__{
          width: w, height: h,
          bit_depth: bit_depth, color_type: color_type,
          compression: cmp, filter: fltr, interlace: intlc
        }
      }
    else
      {:error, _} -> {:error, "malformed IHDR", data}
    end
  end

  defp validate_bit_depth(bd) when bd in [1,2,4,8,16], do: {:ok, bd}
  defp validate_bit_depth(bd), do: {:error, bd}

  defp validate_color_type(ct) when ct in [0,2,3,4,6], do: {:ok, ct}
  defp validate_color_type(ct), do: {:error, ct}
end
