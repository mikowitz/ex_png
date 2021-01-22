defmodule ExPng.Chunks.End do
  @moduledoc false

  defstruct type: "IEND"

  def new("IEND", _data), do: {:ok, %__MODULE__{}}

  def to_bytes(%__MODULE__{}) do
    length = <<0::32>>
    type = <<73, 69, 78, 68>>
    crc = :erlang.crc32([type, <<>>])
    length <> type <> <<crc::32>>
  end
end
