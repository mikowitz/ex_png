defmodule ExPng.Chunks.Palette do
  @moduledoc """
  Representation of the color palette for a PNG image encoded using the
  indexed filter method.
  """

  alias ExPng.Color
  alias ExPng.Chunks.{Header, Transparency}

  import ExPng.Utilities, only: [reduce_to_binary: 1]

  @type t :: %__MODULE__{
    type: :PLTE,
    data: ExPng.maybe(binary()),
    palette: [ExPng.Color.t, ...]
  }
  defstruct [:data, :palette, type: :PLTE]

  @spec new(:PLTE, binary) :: {:ok, __MODULE__.t}
  def new(:PLTE, data) do
    with palette <- parse_palette(data) do
      {:ok, %__MODULE__{data: data, palette: palette}}
    end
  end

  @spec parse_data(ExPng.maybe(__MODULE__.t), ExPng.maybe(Transparency.t), Header.t) :: ExPng.maybe(__MODULE__.t)
  def parse_data(nil, _, _), do: nil
  def parse_data(palette, nil, _), do: palette
  def parse_data(%__MODULE__{} = palette, transparency, %Header{color_mode: 3}) do
    new_palette =
      palette.palette
      |> Enum.with_index()
      |> Enum.map(fn {<<r, g, b, _>>, i} ->
        case Enum.at(transparency.transparency, i) do
          nil -> <<r, g, b, 255>>
          new_a -> <<r, g, b, new_a>>
        end
      end)
    %{palette | palette: new_palette}
  end
  def parse_data(%__MODULE__{} = palette, _, _), do: palette

  @behaviour ExPng.Encodeable

  @impl true
  def to_bytes(%__MODULE__{palette: palette}, _encoding_options \\ []) do
    data =
      Enum.map(palette, fn <<r, g, b, _>> -> <<r, g, b>> end)
      |> reduce_to_binary()
    length = byte_size(data)
    type = <<80, 76, 84, 69>>
    crc = :erlang.crc32([type, data])

    <<length::32>> <> type <> data <> <<crc::32>>
  end

  ## PRIVATE

  defp parse_palette(data) do
    for <<r, g, b <- data>>, do: Color.rgb(r, g, b)
  end
end
