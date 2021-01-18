defmodule ExPng.Chunks.End do
  defstruct [type: "IEND"]

  def new, do: {:ok, %__MODULE__{}}
end
