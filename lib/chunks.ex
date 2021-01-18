defmodule ExPng.Chunks do
  def from_type("IHDR", data) do
    ExPng.Chunks.Header.new(data)
  end
  def from_type("IDAT", data) do
    ExPng.Chunks.ImageData.new(data)
  end
  def from_type("IEND", _data) do
    ExPng.Chunks.End.new()
  end
  def from_type("PLTE", data) do
    ExPng.Chunks.Palette.new(data)
  end
  def from_type(type, data) do
    ExPng.Chunks.Ancillary.new(type, data)
  end
end
