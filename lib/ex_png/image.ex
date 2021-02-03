defmodule ExPng.Image do
  @moduledoc """
  The primary API module for `ExPng`, `ExPng.Image` provides functions for
  reading, editing, and saving images.
  """

  alias ExPng.Image.{Decoding, Drawing, Encoding}
  alias ExPng.RawData

  @type row :: [ExPng.Pixel.t, ...]
  @type canvas :: [row, ...]
  @type t :: %__MODULE__{
    pixels: canvas,
    raw_data: ExPng.RawData.t,
    height: integer(),
    width: integer()
  }
  @type filename :: String.t
  @type success :: {:ok, __MODULE__.t}
  @type error :: {:error, String.t, filename}

  defstruct [
    :pixels,
    :raw_data,
    :height,
    :width
  ]

  @doc """
  Returns a blank (opaque white) image with the provided width and height
  """
  @spec new(integer, integer) :: __MODULE__.t
  def new(width, height) do
    %__MODULE__{
      width: width,
      height: height
    }
    |> erase()
  end

  @doc """
  Constructs a new image from the provided 2-dimensional list of pixels
  """
  @spec new(canvas) :: __MODULE__.t
  def new(pixels) do
    %__MODULE__{
      pixels: pixels,
      width: length(Enum.at(pixels, 0)),
      height: length(pixels)
    }
  end

  @doc """
  Attempts to decode a PNG file into an `ExPng.Image` and returns a success
  tuple `{:ok, image}` or an error tuple explaining the encountered error.

      ExPng.Image.from_file("adorable_kittens.png")
      {:ok, %ExPng.Image{ ... }

      ExPng.Image.from_file("doesnt_exist.png")
      {:error, :enoent, "doesnt_exist.png"}

  """
  @spec from_file(filename) :: success | error
  def from_file(filename) do
    case ExPng.RawData.from_file(filename) do
      {:ok, raw_data} -> {:ok, Decoding.from_raw_data(raw_data)}
      error -> error
    end
  end

  @spec to_file(__MODULE__.t, filename) :: {:ok, filename}
  def to_file(%__MODULE__{} = image, filename, encoding_options \\ []) do
    with {:ok, raw_data} <- Encoding.to_raw_data(image, encoding_options) do
      RawData.to_file(raw_data, filename, encoding_options)
      {:ok, filename}
    end
  end

  defdelegate erase(image), to: Drawing
  defdelegate draw(image, coordinates, color), to: Drawing
  defdelegate at(image, coordinates), to: Drawing
  defdelegate clear(image, coordinates), to: Drawing
  defdelegate line(image, coordinates0, coordinates1, color \\ ExPng.Pixel.black()), to: Drawing

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
