defmodule ExPngTest do
  use ExUnit.Case
  doctest ExPng

  describe "from_file" do
    test "returns a success tuple when the file exists" do
      for file <- Path.wildcard("test/png_suite/basic/*.png") do
        assert {:ok, _} = ExPng.Image.from_file(file)
      end
    end

    test "returns an error tuple when the file doesn't exist" do
      assert {:error, :enoent, "missing.png"} = ExPng.Image.from_file("missing.png")
    end
  end

  describe "from_binary" do
    test "returns a success tuple when the binary is parseable" do
      assert {:ok, _raw_data} =
               ExPng.Image.from_binary(File.read!("test/png_suite/basic/basi2c16.png"))
    end

    test "returns an error tuple when the binary isn't parseable" do
      assert {:error, "malformed IDAT", _data} =
               ExPng.Image.from_binary(
                 File.read!("test/png_suite/broken/image_data/xcsn0g01.png")
               )
    end
  end

  test "returns an error tuple when the file doesn't have the correct PNG signature" do
    for file <- Path.wildcard("test/png_suite/broken/signature/*.png") do
      assert {:error, "malformed PNG signature", ^file} = ExPng.Image.from_file(file)
    end
  end

  test "returns an error tuple when the file's IHDR chunk is corrupted" do
    for file <- Path.wildcard("test/png_suite/broken/header/*.png") do
      assert {:error, "malformed IHDR", ^file} = ExPng.Image.from_file(file)
    end
  end

  test "returns an error tuple when the file is missing an IDAT chunk" do
    with file <- "test/png_suite/broken/image_data/xdtn0g01.png" do
      assert {:error, "missing IDAT chunks", ^file} = ExPng.Image.from_file(file)
    end
  end

  test "returns an error tuple when the IDAT chunk is corrupted" do
    with file <- "test/png_suite/broken/image_data/xcsn0g01.png" do
      assert {:error, "malformed IDAT", ^file} = ExPng.Image.from_file(file)
    end
  end
end
