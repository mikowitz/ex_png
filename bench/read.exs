filename = "prof/kitten.png"
{:ok, image} = ExPng.Image.from_file(filename)

bench_name = "#{Date.to_string(Date.utc_today)}-#{Time.to_string(Time.utc_now)}"

Benchee.run(
  %{
    "read" => fn -> ExPng.Image.from_file(filename) end
  },
  time: 10,
  warmup: 5,
  parallel: 4,
  formatters: [{Benchee.Formatters.Console, extended_statistics: true}],
  save: [path: "bench/results/read/#{bench_name}"]
)
