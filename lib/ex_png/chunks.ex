defmodule ExPng.Chunks do
  @moduledoc false

  def from_type(type, data) do
    module =
      case type do
        :IHDR -> ExPng.Chunks.Header
        :IDAT -> ExPng.Chunks.ImageData
        :IEND -> ExPng.Chunks.End
        :PLTE -> ExPng.Chunks.Palette
        :tRNS -> ExPng.Chunks.Transparency
        _ -> ExPng.Chunks.Ancillary
      end

    module.new(type, data)
  end
end
