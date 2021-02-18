defmodule WriteBench do
  # use Benchfella

  {:ok, kitten} = ExPng.Image.from_file("prof/large.png")
  @kitten kitten

  # teardown_all nil do
  #   File.rm("write_bench.png")
  # end

  # bench "no filtering, default compression" do
  #   ExPng.Image.to_file(@kitten, "write_bench.png")
  #   IO.inspect File.stat!("write_bench.png").size
  # end

  # bench "paeth filtering, default compression" do
  #   ExPng.Image.to_file(@kitten, "write_bench.png", filter: ExPng.Image.Filtering.paeth)
  #   IO.inspect File.stat!("write_bench.png").size
  # end

  # bench "no filtering, max compression" do
  #   ExPng.Image.to_file(@kitten, "write_bench.png", compression: 9)
  #   IO.inspect File.stat!("write_bench.png").size
  # end

  # bench "paeth filtering, max compression" do
  #   ExPng.Image.to_file(@kitten, "write_bench.png", filter: ExPng.Image.Filtering.paeth, compression: 9)
  #   IO.inspect File.stat!("write_bench.png").size
  # end

  # bench "no filtering, no compression" do
  #   ExPng.Image.to_file(@kitten, "write_bench.png", compression: 0)
  #   IO.inspect File.stat!("write_bench.png").size
  # end

  # bench "paeth filtering, no compression" do
  #   ExPng.Image.to_file(@kitten, "write_bench.png", filter: ExPng.Image.Filtering.paeth, compression: 0)
  #   IO.inspect File.stat!("write_bench.png").size
  # end

  Benchee.run(
    %{
      "no filter, no compression" => fn -> ExPng.Image.to_file(@kitten, "write_bench-00.png", filter: ExPng.Image.Filtering.none, compression: 0) end,
      "no filter, default compression" => fn -> ExPng.Image.to_file(@kitten, "write_bench-06.png", filter: ExPng.Image.Filtering.none, compression: 6) end,
      "no filter, max compression" => fn -> ExPng.Image.to_file(@kitten, "write_bench-09.png", filter: ExPng.Image.Filtering.none, compression: 9) end,
      "up filter, no compression" => fn -> ExPng.Image.to_file(@kitten, "write_bench-20.png", filter: ExPng.Image.Filtering.up, compression: 0) end,
      "up filter, default compression" => fn -> ExPng.Image.to_file(@kitten, "write_bench-26.png", filter: ExPng.Image.Filtering.up, compression: 6) end,
      "up filter, max compression" => fn -> ExPng.Image.to_file(@kitten, "write_bench-29.png", filter: ExPng.Image.Filtering.up, compression: 9) end,
      "paeth filter, no compression" => fn -> ExPng.Image.to_file(@kitten, "write_bench-40.png", filter: ExPng.Image.Filtering.paeth, compression: 0) end,
      "paeth filter, default compression" => fn -> ExPng.Image.to_file(@kitten, "write_bench-46.png", filter: ExPng.Image.Filtering.paeth, compression: 6) end,
      "paeth filter, max compression" => fn -> ExPng.Image.to_file(@kitten, "write_bench-49.png", filter: ExPng.Image.Filtering.paeth, compression: 9) end,
    }
  )

  File.rm("write_bench.png")
end

