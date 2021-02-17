defmodule ExPng.Image.FilteringTest do
  use ExUnit.Case

  alias ExPng.{Image.Filtering}

  doctest Filtering

  describe "unfiltering" do
    test "should decode a line without filtering as is" do
      line = {
        0,
        <<255, 255, 255, 255, 255, 255, 255, 255, 255>>
      }

      filtered = Filtering.unfilter(line, 3)
      assert filtered == <<255, 255, 255, 255, 255, 255, 255, 255, 255>>
    end

    test "should decode a line with sub filtering correctly" do
      line = {
        1,
        <<255, 255, 255, 0, 0, 0, 0, 0, 0>>
      }

      filtered = Filtering.unfilter(line, 3)
      assert filtered == <<255, 255, 255, 255, 255, 255, 255, 255, 255>>

      line = {
        1,
        <<0, 0, 0, 0, 0, 0, 0, 0, 0>>
      }

      filtered = Filtering.unfilter(line, 3)
      assert filtered == <<0, 0, 0, 0, 0, 0, 0, 0, 0>>

      line = {
        1,
        <<255, 0, 45, 0, 255, 0, 112, 200, 178>>
      }

      filtered = Filtering.unfilter(line, 3)
      assert filtered == <<255, 0, 45, 255, 255, 45, 111, 199, 223>>
    end

    test "should decode a line with up filtering correctly if there is no previous line" do
      line = {
        2,
        <<0, 127, 255, 0, 127, 255, 0, 127, 255>>
      }

      filtered = Filtering.unfilter(line, 3, nil)
      assert filtered == <<0, 127, 255, 0, 127, 255, 0, 127, 255>>
    end

    test "should decode a line with up filtering correctly" do
      prev = {
        2,
        <<255, 255, 255, 127, 127, 127, 0, 0, 0>>
      }

      line = {
        2,
        <<0, 127, 255, 0, 127, 255, 0, 127, 255>>
      }

      filtered = Filtering.unfilter(line, 3, prev)
      assert filtered == <<255, 126, 254, 127, 254, 126, 0, 127, 255>>
    end

    test "should decode a line with average filtering correctly" do
      prev = {
        3,
        <<10, 20, 30, 40, 50, 60, 70, 80, 80, 100, 110, 120>>
      }

      line = {
        3,
        <<0, 0, 10, 23, 15, 13, 23, 63, 38, 60, 253, 53>>
      }

      filtered = Filtering.unfilter(line, 3, prev)
      assert filtered == <<5, 10, 25, 45, 45, 55, 80, 125, 105, 150, 114, 165>>
    end

    test "should decode a line with Paeth filtering correctly" do
      prev = {
        4,
        <<10, 20, 30, 40, 50, 60, 70, 80, 80, 100, 110, 120>>
      }

      line = {
        4,
        <<0, 0, 10, 20, 10, 0, 0, 40, 10, 20, 190, 0>>
      }

      filtered = Filtering.unfilter(line, 3, prev)
      assert filtered == <<10, 20, 40, 60, 60, 60, 70, 120, 90, 120, 54, 120>>
    end
  end

  describe "apply_filter" do
    test "should encode a line with no filtering as is" do
      line = {
        0,
        <<255, 255, 255, 255, 255, 255, 255, 255, 255>>
      }

      filtered = Filtering.apply_filter(line, 3)
      assert filtered == <<255, 255, 255, 255, 255, 255, 255, 255, 255>>
    end

    test "should encode a line with sub filtering correctly" do
      line = {
        1,
        <<255, 255, 255, 255, 255, 255, 255, 255, 255>>
      }

      filtered = Filtering.apply_filter(line, 3)
      assert filtered == <<255, 255, 255, 0, 0, 0, 0, 0, 0>>

      line = {
        1,
        <<0, 0, 0, 0, 0, 0, 0, 0, 0>>
      }

      filtered = Filtering.apply_filter(line, 3)
      assert filtered == <<0, 0, 0, 0, 0, 0, 0, 0, 0>>

      line = {
        1,
        <<254, 0, 45, 255, 255, 45, 111, 199, 223>>
      }

      filtered = Filtering.apply_filter(line, 3)
      assert filtered == <<254, 0, 45, 1, 255, 0, 112, 200, 178>>
    end

    test "should encode a line with up filtering correctly" do
      prev = {
        2,
        <<255, 255, 255, 127, 127, 127, 0, 0, 0>>
      }

      line = {
        2,
        <<255, 126, 254, 127, 254, 126, 0, 127, 255>>
      }

      filtered = Filtering.apply_filter(line, 3, prev)
      assert filtered == <<0, 127, 255, 0, 127, 255, 0, 127, 255>>
    end

    test "encoding a line with up filtering with no previous line returns the line itself" do
      line = {
        2,
        <<255, 126, 254, 127, 254, 126, 0, 127, 255>>
      }

      filtered = Filtering.apply_filter(line, 3)
      assert filtered == <<255, 126, 254, 127, 254, 126, 0, 127, 255>>
    end

    test "should encode a line with average filtering correctly" do
      prev = {
        3,
        <<10, 20, 30, 40, 50, 60, 70, 80, 80, 100, 110, 120>>
      }

      line = {
        3,
        <<5, 10, 25, 45, 45, 55, 80, 125, 105, 150, 114, 165>>
      }

      filtered = Filtering.apply_filter(line, 3, prev)
      assert filtered == <<0, 0, 10, 23, 15, 13, 23, 63, 38, 60, 253, 53>>
    end

    test "should encode a line with Paeth filtering correctly" do
      prev = {
        4,
        <<10, 20, 30, 40, 50, 60, 70, 80, 80, 100, 110, 120>>
      }

      line = {
        4,
        <<10, 20, 40, 60, 60, 60, 70, 120, 90, 120, 54, 120>>
      }

      filtered = Filtering.apply_filter(line, 3, prev)
      assert filtered == <<0, 0, 10, 20, 10, 0, 0, 40, 10, 20, 190, 0>>
    end
  end
end
