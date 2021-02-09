defmodule ExPng.Chunks.Header do
  @moduledoc """
  Stores the data collected from a PNG's header data chunk. This chunk enodes
  information about

    * the image's width and height
    * the bit_depth of encoded pixel data
    * the color mode the image pixel data is stored in
    * whether the image data has been interlaced using the Adam7 interlacing
      algorithm
    * the filter _method_ applied to the image. This is different than the
      filter _type_ used by each line of the image (see `ExPng.Image.Line`),
      and the only current valid value for this field is `0`
    * the compression method applied to the image data. Like the filter
      method, `0` is the only allowed value for this field. PNG uses the
      [DEFLATE](https://en.wikipedia.org/wiki/Deflate) compression algorithm,
      and `ExPng` uses Erlang's implementation of [zlib](https://en.wikipedia.org/wiki/Zlib).

  The data contained in this struct is read from a PNG when decoding, and generated
  automatically for an image when encoding, so `ExPng` users should never have to
  manipulate this data manually.
  """

  @type t :: %__MODULE__{
    width: integer,
    height: integer,
    bit_depth: ExPng.bit_depth,
    color_mode: ExPng.color_mode,
    compression: 0,
    filter: 0,
    interlace: 0 | 1,
    type: :IHDR
  }
  defstruct [
    :width,
    :height,
    :bit_depth,
    :color_mode,
    :compression,
    :filter,
    :interlace,
    type: :IHDR
  ]

  @spec new(:IHDR, <<_::25>>) :: __MODULE__.t
  def new(:IHDR, <<w::32, h::32, bd, ct, cmp, fltr, intlc>> = data) do
    with {:ok, bit_depth} <- validate_bit_depth(bd),
         {:ok, color_mode} <- validate_color_mode(ct) do
      {
        :ok,
        %__MODULE__{
          width: w,
          height: h,
          bit_depth: bit_depth,
          color_mode: color_mode,
          compression: cmp,
          filter: fltr,
          interlace: intlc
        }
      }
    else
      {:error, _, _} -> {:error, "malformed IHDR", data}
    end
  end

  @behaviour ExPng.Encodeable

  @impl true
  def to_bytes(%__MODULE__{} = header, _opts \\ []) do
    with {:ok, bit_depth} <- validate_bit_depth(header.bit_depth),
         {:ok, color_mode} <- validate_color_mode(header.color_mode) do
      length = <<13::32>>
      type = <<73, 72, 68, 82>>

      data =
        <<header.width::32, header.height::32, bit_depth, color_mode, header.compression,
          header.filter, header.interlace>>

      crc = :erlang.crc32([type, data])
      length <> type <> data <> <<crc::32>>
    else
      error -> error
    end
  end

  ## PRIVATE

  defp validate_bit_depth(bd) when bd in [1, 2, 4, 8, 16], do: {:ok, bd}
  defp validate_bit_depth(bd), do: {:error, "invalid bit depth", bd}

  defp validate_color_mode(ct) when ct in [0, 2, 3, 4, 6], do: {:ok, ct}
  defp validate_color_mode(ct), do: {:error, "invalid color type", ct}
end
