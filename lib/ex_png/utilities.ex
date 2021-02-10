defmodule ExPng.Utilities do
  @moduledoc """
  Shared utility functions.
  """

  @doc """
  Accepts a list of binaries and reduces them to a single
  binary
  """
  @spec reduce_to_binary([binary]) :: binary
  def reduce_to_binary(list) do
    list
    |> Enum.reverse()
    |> Enum.reduce(&Kernel.<>/2)
  end
end
