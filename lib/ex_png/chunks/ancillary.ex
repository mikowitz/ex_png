defmodule ExPng.Chunks.Ancillary do
  @moduledoc false

  defstruct [:type, :data]

  def new(type, data) do
    {:ok, %__MODULE__{type: type, data: data}}
  end
end
