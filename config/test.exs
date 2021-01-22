use Mix.Config

config :mix_test_watch,
  tasks: [
    "test",
    "coveralls.html",
    "format",
    "credo --strict"
  ]
