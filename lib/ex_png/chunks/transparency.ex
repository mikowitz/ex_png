defmodule ExPng.Chunks.Transparency do
  @moduledoc """
  Representation of transparency data for an image
  """

  @type t :: %__MODULE__{
          type: :tRNS,
          data: ExPng.maybe(binary()),
          transparency: ExPng.maybe([integer()] | binary())
        }
  defstruct [:data, :transparency, type: :tRNS]

  alias ExPng.Chunks.Header
  import ExPng.Utilities, only: [reduce_to_binary: 1]
  import Bitwise

  @spec new(:tRNS, binary) :: {:ok, __MODULE__.t()}
  def new(:tRNS, data) do
    {:ok, %__MODULE__{data: data}}
  end

  @spec build_from_pixel_palette([ExPng.Color.t()]) :: ExPng.maybe(__MODULE__.t())
  def build_from_pixel_palette(pixels) do
    transparency =
      pixels
      |> Enum.map(fn <<_, _, _, a>> -> a end)
      |> Enum.take_while(fn a -> a < 255 end)

    case transparency do
      [] -> nil
      _ -> %__MODULE__{transparency: transparency}
    end
  end

  @spec parse_data(ExPng.maybe(__MODULE__.t()), Header.t()) ::
          {:ok, ExPng.maybe(__MODULE__.t())} | {:error, binary()}
  def parse_data(nil, _), do: {:ok, nil}

  def parse_data(%__MODULE__{data: data} = transparency, %Header{color_mode: 3}) do
    transparencies = for <<a <- data>>, do: a
    {:ok, %{transparency | transparency: transparencies}}
  end

  def parse_data(%__MODULE__{data: data} = transparency, %Header{
        color_mode: 0,
        bit_depth: bit_depth
      }) do
    gray =
      data
      |> :binary.decode_unsigned()
      |> shape_transparency_bit(bit_depth)

    {:ok, %{transparency | transparency: <<gray, gray, gray>>}}
  end

  def parse_data(%__MODULE__{data: data} = transparency, %Header{
        color_mode: 2,
        bit_depth: bit_depth
      }) do
    <<r::bytes-size(2), g::bytes-size(2), b::bytes-size(2)>> = data

    [r, g, b] = [r, g, b] |> Enum.map(&:binary.decode_unsigned/1)

    transparent_pixel =
      case bit_depth do
        1 ->
          if r == 0x01, do: <<255, 255, 255>>, else: <<0, 0, 0>>

        _ ->
          [r, g, b] = Enum.map([r, g, b], &shape_transparency_bit(&1, bit_depth))
          <<r, g, b>>
      end

    {:ok, %{transparency | transparency: transparent_pixel}}
  end

  def parse_data(_, _), do: {:error, "invalid transparency chunk"}

  @behaviour ExPng.Encodeable

  @impl true
  def to_bytes(%__MODULE__{transparency: transparency}, _encoding_options \\ []) do
    data =
      Enum.map(transparency, fn a -> <<a>> end)
      |> reduce_to_binary()

    length = byte_size(data)
    type = <<116, 82, 78, 83>>
    crc = :erlang.crc32([type, data])
    <<length::32>> <> type <> data <> <<crc::32>>
  end

  defp shape_transparency_bit(0x01, 1), do: 0xFF
  defp shape_transparency_bit(_, 1), do: 0x0

  defp shape_transparency_bit(bit, 2) do
    bit <<< 6 ||| bit <<< 4 ||| bit <<< 2 ||| bit
  end

  defp shape_transparency_bit(bit, 4) do
    bit <<< 4 ||| bit
  end

  defp shape_transparency_bit(bit, 8) do
    bit
  end

  defp shape_transparency_bit(bit, 16) do
    bit >>> 8
  end
end
