import Config

config :mix_test_watch,
  tasks: [
    "test",
    "coveralls.html",
    "docs",
    "credo --all"
  ]
