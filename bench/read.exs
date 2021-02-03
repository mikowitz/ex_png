bench_name = "#{Date.to_string(Date.utc_today)}-#{Time.to_string(Time.utc_now)}"

Benchee.run(
  %{
    "read" => fn input -> ExPng.Image.from_file(input) end
  },
  inputs: %{
    "small" => "prof/kitten.png",
    "large" => "prof/large.png"
  },
  time: 10,
  warmup: 5,
  parallel: 8,
  formatters: [{Benchee.Formatters.Console, extended_statistics: true}],
  save: [path: "bench/results/read/#{bench_name}"]
)
