defmodule ExPng.Image.Adam7Test do
  use ExUnit.Case

  alias ExPng.Image.Adam7

  describe "pass sizes" do
    test "it returns the correct values for a 32x32 image" do
      assert Adam7.pass_sizes(32, 32) ==
               [[4, 4], [4, 4], [8, 4], [8, 8], [16, 8], [16, 16], [32, 16]]
    end
  end
end
