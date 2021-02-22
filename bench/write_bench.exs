defmodule WriteBench do
  # use Benchfella

  {:ok, kitten} = ExPng.Image.from_file("prof/large.png")
  @kitten kitten

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
    },
    time: 10
  )

  File.rm("write_bench.png")
end

