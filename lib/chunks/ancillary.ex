defmodule ExPng.Chunks.Ancillary do
  defstruct [:type, :data]

  def new(type, data)do
    {:ok, %__MODULE__{type: type, data: data}}
  end
end
