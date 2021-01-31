defmodule ExPng.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_png,
      name: "ExPng",
      description: description(),
      package: package(),
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.10", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.21", only: [:dev, :test], runtime: false},
      {:mix_test_watch, "~> 1.0", only: [:dev, :test], runtime: false}
    ]
  end

  defp description do
    "A pure Elixir implementation of the PNG image format."
  end

  defp package do
    [
      name: "ex_png",
      files: ~w(lib mix.exs README* UNLICENSE),
      licenses: ["UNLICENSE"],
      links: %{
        "GitHub" => "https://github.com/mikowitz/ex_png"
      }
    ]
  end
end
