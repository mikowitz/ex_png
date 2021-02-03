{:ok, image} = ExPng.Image.from_file("prof/kitten.png")
{:ok, large_image} = ExPng.Image.from_file("prof/large.png")

bench_name = "#{Date.to_string(Date.utc_today)}-#{Time.to_string(Time.utc_now)}"

Benchee.run(
  %{
    "small, 0-comp" => fn -> ExPng.Image.to_file(image, "benchee.png", compression_level: 0) end,
    "small, 1-comp" => fn -> ExPng.Image.to_file(image, "benchee.png", compression_level: 1) end,
    "small, 6-comp" => fn -> ExPng.Image.to_file(image, "benchee.png", compression_level: 6) end,
    "small, 9-comp" => fn -> ExPng.Image.to_file(image, "benchee.png", compression_level: 9) end,
    "large, 0-comp" => fn -> ExPng.Image.to_file(large_image, "benchee.png", compression_level: 0) end,
    "large, 1-comp" => fn -> ExPng.Image.to_file(large_image, "benchee.png", compression_level: 1) end,
    "large, 6-comp" => fn -> ExPng.Image.to_file(large_image, "benchee.png", compression_level: 6) end,
    "large, 9-comp" => fn -> ExPng.Image.to_file(large_image, "benchee.png", compression_level: 9) end
  },
  time: 20,
  warmup: 5,
  formatters: [{Benchee.Formatters.Console, extended_statistics: true}],
  save: [path: "bench/results/write/#{bench_name}"],
  after_scenario: fn _ -> File.rm("benchee.png") end
)

File.rm("benchee.png")

