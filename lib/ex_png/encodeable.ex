defmodule ExPng.Encodeable do
  @moduledoc """
  `ExPng.Encodeable` is a basic behaviour to mark a raw data chunk as encodeable
  and provide a callback to convert the struct to a binary bytestring to be
  written to a PNG file.
  """
  @callback to_bytes(term, ExPng.maybe(keyword)) :: binary()
end
