defmodule ExPng.Chunks.HeaderTest do
  use ExUnit.Case

  alias ExPng.Chunks.Header

  describe "to_bytes" do
    test "it returns the correct bytestring for encoding the header data" do
      header = %Header{
        width: 30,
        height: 17,
        bit_depth: 2,
        color_type: 4,
        compression: 0,
        filter: 0,
        interlace: 0
      }

      bytes = Header.to_bytes(header)

      assert <<
               0,
               0,
               0,
               13,
               73,
               72,
               68,
               82,
               0,
               0,
               0,
               30,
               0,
               0,
               0,
               17,
               2,
               4,
               0,
               0,
               0,
               42,
               223,
               204,
               93
             >> = bytes
    end

    test "it raises an error if an invalid bit depth is passed" do
      header = %Header{
        width: 30,
        height: 17,
        bit_depth: 9,
        color_type: 4,
        compression: 0,
        filter: 0,
        interlace: 0
      }

      assert {:error, "invalid bit depth", 9} == Header.to_bytes(header)
    end

    test "it raises an error if an invalid color type is passed" do
      header = %Header{
        width: 30,
        height: 17,
        bit_depth: 2,
        color_type: 7,
        compression: 0,
        filter: 0,
        interlace: 0
      }

      assert {:error, "invalid color type", 7} == Header.to_bytes(header)
    end
  end
end
