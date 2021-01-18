defmodule ExPng.ImageTest do
  use ExUnit.Case

  alias ExPng.Image

  describe "to_lines" do
    test "it returns the correct number of lines for the image" do
      for file <- Path.wildcard("test/png_suite/basic/*.png") do
        {:ok, image} = ExPng.from_file(file)
        image = Image.to_lines(image)
        assert length(image.lines) == image.header.height
      end
    end
  end
end
