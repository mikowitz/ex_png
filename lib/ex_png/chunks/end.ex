defmodule ExPng.Chunks.End do
  @moduledoc """
  Representation of the IEND final chunk in an encoded PNG image. This is an
  empty data chunk, but required for properly decoding an image to mark the end
  of the image's data, and serves as a bookend when encoding an `ExPng.Image`
  to PNG.
  """

  @type t :: %__MODULE__{
    type: :IEND
  }
  defstruct type: :IEND

  @doc """
  Creates a new End chunk.
  """
  @spec new(:IEND, term()) :: __MODULE__.t
  def new(:IEND, _data), do: {:ok, %__MODULE__{}}

  @behaviour ExPng.Encodeable

  @impl true
  def to_bytes(%__MODULE__{}, _opts \\ []) do
    length = <<0::32>>
    type = <<73, 69, 78, 68>>
    crc = :erlang.crc32([type, <<>>])
    length <> type <> <<crc::32>>
  end
end
