defmodule ExPng.Image do
  @moduledoc false

  alias ExPng.Image.{Decoding, Drawing, Encoding}
  alias ExPng.RawData

  defstruct [
    :pixels,
    :raw_data,
    :height,
    :width
  ]

  def new(width, height) do
    pixels = build_pixels(width, height)

    %__MODULE__{
      pixels: pixels,
      width: width,
      height: height
    }
  end
  def new(pixels) do
    %__MODULE__{
      pixels: pixels,
      width: length(Enum.at(pixels, 0)),
      height: length(pixels)
    }
  end

  def from_file(filename) do
    case ExPng.RawData.from_file(filename) do
      {:ok, raw_data} -> {:ok, from_raw_data(raw_data)}
      error -> error
    end
  end

  def to_file(%__MODULE__{} = image, filename) do
    with {:ok, raw_data} <- to_raw_data(image) do
      RawData.to_png(raw_data, filename)
      {:ok, filename}
    end
  end

  defdelegate to_raw_data(image), to: Encoding
  defdelegate from_raw_data(raw_data), to: Decoding

  defp build_pixels(width, height) do
    for _ <- 1..height do
      Stream.cycle([ExPng.Pixel.white()]) |> Enum.take(width)
    end
  end

  defdelegate draw(image, xy, color), to: Drawing
  defdelegate at(image, xy), to: Drawing
  defdelegate clear(image, xy), to: Drawing

  def erase(%__MODULE__{} = image) do
    %{
      image
      | pixels: build_pixels(image.width, image.height)
    }
  end

  def line(%__MODULE__{} = image, x0, y0, x1, y1, color \\ ExPng.Pixel.black()) do
    dx = x1 - x0
    dy = y1 - y0

    drawing_func =
      case {abs(dx), abs(dy)} do
        {_, 0} -> :draw_horizontal_line
        {0, _} -> :draw_vertical_line
        {d, d} -> :draw_diagonal_line
        _ -> :draw_line
      end

    apply(Drawing, drawing_func, [image, x0, y0, x1, y1, color])
  end

  @behaviour Access

  @impl true
  def fetch(%__MODULE__{} = image, {x, y}) do
    case x < image.width && y < image.height do
      true ->
        pixel =
          image.pixels
          |> Enum.at(y)
          |> Enum.at(x)

        {:ok, pixel}

      false ->
        :error
    end
  end

  @impl true
  def get_and_update(%__MODULE__{} = image, {x, y}, func) do
    case fetch(image, {x, y}) do
      {:ok, pixel} ->
        {_, new_pixel} = func.(pixel)

        row =
          image.pixels
          |> Enum.at(round(y))
          |> List.replace_at(round(x), new_pixel)

        pixels = List.replace_at(image.pixels, round(y), row)
        {pixel, %{image | pixels: pixels}}

      :error ->
        {nil, image}
    end
  end

  @impl true
  def pop(%__MODULE__{} = image, {x, y}) do
    update_in(image, [{x, y}], fn _ -> ExPng.Pixel.white() end)
  end
end

defimpl Inspect, for: ExPng.Image do
  def inspect(%ExPng.Image{pixels: pixels}, _opts) do
    for line <- pixels do
      Enum.map(line, &inspect/1)
      |> Enum.join(" ")
    end
    |> Enum.join("\n")
  end
end
