defmodule WriteBench do
  use Benchfella

  {:ok, kitten} = ExPng.Image.from_file("prof/kitten.png")
  {:ok, large} = ExPng.Image.from_file("prof/large.png")
  @kitten kitten
  @large large

  teardown_all nil do
    File.rm("write_bench.png")
  end

  bench "write smaller image" do
    ExPng.Image.to_file(@kitten, "write_bench.png")
  end

  bench "write larger image" do
    ExPng.Image.to_file(@large, "write_bench.png")
  end
end

