defmodule CompressionBench do
  use Benchfella

  {:ok, kitten} = ExPng.Image.from_file("prof/kitten.png")
  @kitten kitten

  teardown_all nil do
    File.rm("write_bench.png")
  end

  bench "zero compression" do
    ExPng.Image.to_file(@kitten, "write_bench.png", compression: 0)
  end

  bench "compression level 1" do
    ExPng.Image.to_file(@kitten, "write_bench.png", compression: 1)
  end

  bench "compression level 6" do
    ExPng.Image.to_file(@kitten, "write_bench.png", compression: 6)
  end

  bench "compression level 9" do
    ExPng.Image.to_file(@kitten, "write_bench.png", compression: 9)
  end
end
