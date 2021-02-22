defmodule ReadBench do
  @kitten "prof/kitten.png"

  Benchee.run(
    %{
      "read" => fn -> ExPng.Image.from_file(@kitten) end
    }
  )
end
