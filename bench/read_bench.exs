defmodule ReadBench do
  use Benchfella

  @kitten "prof/kitten.png"
  @large "prof/large.png"

  bench "read smaller image" do
    ExPng.Image.from_file(@kitten)
  end

  bench "read larger image" do
    ExPng.Image.from_file(@large)
  end
end
