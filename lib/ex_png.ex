defmodule ExPng do
  @moduledoc false

  defmodule Constants do
    @moduledoc false

    defmacro __using__(_) do
      quote do
        @grayscale 0
        @truecolor 2
        @indexed 3
        @grayscale_alpha 4
        @truecolor_alpha 6

        @filter_none 0
        @filter_sub 1
        @filter_up 2
        @filter_average 3
        @filter_paeth 4
      end
    end
  end
end
