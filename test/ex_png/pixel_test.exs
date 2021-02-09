defmodule ExPng.PixelTest do
  use ExUnit.Case
  use ExPng.Constants

  alias ExPng.Pixel
  doctest Pixel

  test "grayscale?" do
    assert Pixel.grayscale?(Pixel.black())
    assert Pixel.grayscale?(Pixel.white())
    assert Pixel.grayscale?(Pixel.rgb(100, 100, 100))
    refute Pixel.grayscale?(Pixel.rgb(100, 101, 100))
  end

  test "opaque?" do
    assert Pixel.opaque?(Pixel.black())
    assert Pixel.opaque?(Pixel.white())
    assert Pixel.opaque?(Pixel.rgb(100, 100, 100))
    assert Pixel.opaque?(Pixel.rgb(100, 101, 100))
    refute Pixel.opaque?(Pixel.rgba(100, 101, 100, 100))
  end

  describe "to_bytes" do
    setup do
      {:ok, pixel: Pixel.rgba(50, 150, 200, 250)}
    end

    test "when the color_mode is truecolor_alpha", setup do
      assert Pixel.to_bytes(setup.pixel, @truecolor_alpha) == <<50, 150, 200, 250>>
    end

    test "when the color_mode is truecolor", setup do
      assert Pixel.to_bytes(setup.pixel, @truecolor) == <<50, 150, 200>>
    end

    test "when the color_mode is grayscale", setup do
      assert Pixel.to_bytes(setup.pixel, @grayscale) == <<50>>
    end

    test "when the color_mode is grayscale_alpha", setup do
      assert Pixel.to_bytes(setup.pixel, @grayscale_alpha) == <<50, 250>>
    end
  end

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
