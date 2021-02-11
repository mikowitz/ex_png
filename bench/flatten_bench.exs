defmodule FlattenBench do
  use Benchfella

  @list 1..10_000

  bench "reduce range" do
    Enum.reduce(1..100_000, 0, &Kernel.+(&1 * 2, &2))
  end

  bench "reduce list" do
    Enum.reduce(Enum.to_list(1..100_000), 0, &Kernel.+(&1 * 2, &2))
  end
end
