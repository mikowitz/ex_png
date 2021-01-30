defmodule ExPng.PixelTest do
  use ExUnit.Case

  alias ExPng.Pixel
  doctest Pixel

  describe "inspect" do
    test "it returns a 10-character hex representation of the pixel" do
      assert Pixel.black() |> inspect == "0x000000ff"
      assert Pixel.white() |> inspect == "0xffffffff"

      assert Pixel.rgb(254, 0, 0) |> inspect == "0xfe0000ff"
      assert Pixel.rgba(10, 200, 250, 100) |> inspect == "0x0ac8fa64"

      assert Pixel.grayscale(20) |> inspect == "0x141414ff"
      assert Pixel.grayscale(8, 20) |> inspect == "0x08080814"
    end
  end
end
