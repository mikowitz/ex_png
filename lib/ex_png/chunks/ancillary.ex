defmodule ExPng.Chunks.Ancillary do
  @moduledoc """
  Struct storage format for any ancillary chunks present in a parsed PNG image
  file. Currently `ExPng` does not make use of these, but saves them in order to
  retain the full original state of an image's raw data.
  """

  @type t :: %__MODULE__{
    type: atom,
    data: binary
  }
  defstruct [:type, :data]

  @doc """
  Returns a new ancillary chunk built from the provided chunk type and binary data.
  """
  @spec new(atom, binary) :: __MODULE__.t
  def new(type, data) do
    {:ok, %__MODULE__{type: type, data: data}}
  end
end
