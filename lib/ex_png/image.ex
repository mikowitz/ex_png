defmodule ExPng.Image do
  @moduledoc false

  alias ExPng.Image.{Decoding, Encoding}
  alias ExPng.RawData

  defstruct [
    :pixels,
    :raw_data,
    :height,
    :width
  ]

  def from_file(filename) do
    case ExPng.RawData.from_file(filename) do
      {:ok, raw_data} -> {:ok, from_raw_data(raw_data)}
      error -> error
    end
  end

  def to_file(%__MODULE__{} = image, filename) do
    with {:ok, raw_data} <- to_raw_data(image) do
      RawData.to_png(raw_data, filename)
      {:ok, filename}
    end
  end

  defdelegate to_raw_data(image), to: Encoding
  defdelegate from_raw_data(raw_data), to: Decoding
end
