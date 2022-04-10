defmodule ExPng.Image do
  @moduledoc """
  The primary API module for `ExPng`, `ExPng.Image` provides functions for
  reading, editing, and saving images.
  """

  alias ExPng.Image.{Decoding, Drawing, Encoding}
  alias ExPng.{Color, RawData}

  @type row :: [Color.t(), ...]
  @type canvas :: [row, ...]
  @type t :: %__MODULE__{
          pixels: ExPng.maybe(canvas),
          raw_data: ExPng.maybe(RawData.t()),
          height: pos_integer(),
          width: pos_integer()
        }
  @type filename :: String.t()
  @type success :: {:ok, __MODULE__.t()}
  @type error :: {:error, String.t(), filename}

  defstruct [
    :pixels,
    :raw_data,
    :height,
    :width
  ]

  @doc """
  Returns a blank (opaque white) image with the provided width and height
  """
  @spec new(pos_integer, pos_integer) :: __MODULE__.t()
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
  @spec new(canvas) :: __MODULE__.t()
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

  @doc """
  Attempts to decode PNG binary data into an `ExPng.Image` and returns a success
  tuple `{:ok, image}` or an error tuple explaining the encountered error.

      File.read!("test/png_suite/basic/basi2c16.png") |> ExPng.Image.from_binary()
      {:ok, %ExPng.Image{ ... }

      ExPng.Image.from_binary("bad data")
      {:error, "malformed PNG signature", "bad data"}

  """
  @spec from_binary(binary) :: success | error
  def from_binary(binary_data) do
    case ExPng.RawData.from_binary(binary_data) do
      {:ok, raw_data} -> {:ok, Decoding.from_raw_data(raw_data)}
      error -> error
    end
  end

  @doc """
  Writes the `image` to disk at `filename` using the provided
  `encoding_options`.

  Encoding options can be:

  * interlace: whether or not the image in encoding with Adam7 interlacing.
    * defaults to `false`
  * filter: the filtering algorithm to use. Can be one of `ExPng.Image.Filtering.{none, sub, up, average, paeth}`
    * defaults to `up`
  * compression: the compression level for the zlib compression algorithm to use. Can be an integer between 0 (no compression) and 9 (max compression)
    * defaults to 6

  """
  @spec to_file(__MODULE__.t(), filename, ExPng.maybe(keyword)) :: {:ok, filename}
  def to_file(%__MODULE__{} = image, filename, encoding_options \\ []) do
    with {:ok, raw_data} <- Encoding.to_raw_data(image, encoding_options) do
      RawData.to_file(raw_data, filename, encoding_options)
      {:ok, filename}
    end
  end

  @doc """
  Computes the png binary data using the provided
  `encoding_options`.

  Encoding options can be:

  * interlace: whether or not the image is encoding with Adam7 interlacing.
    * defaults to `false`
  * filter: the filtering algorithm to use. Can be one of `ExPng.Image.Filtering.{none, sub, up, average, paeth}`
    * defaults to `up`
  * compression: the compression level for the zlib compression algorithm to use. Can be an integer between 0 (no compression) and 9 (max compression)
    * defaults to 6

  """
  @spec to_binary(__MODULE__.t(), ExPng.maybe(keyword)) :: {:ok, binary}
  def to_binary(%__MODULE__{} = image, encoding_options \\ []) do
    with {:ok, raw_data} <- Encoding.to_raw_data(image, encoding_options) do
      png_binary = RawData.to_binary(raw_data, encoding_options)
      {:ok, png_binary}
    end
  end

  @doc """
  Returns a list of unique pixels values used in `image`.
  """
  @spec unique_pixels(__MODULE__.t()) :: [Color.t()]
  def unique_pixels(%__MODULE__{pixels: pixels}) do
    pixels
    |> List.flatten()
    |> Enum.uniq()
    |> Enum.sort_by(fn <<_, _, _, a>> -> a end)
  end

  defdelegate erase(image), to: Drawing
  defdelegate draw(image, coordinates, color), to: Drawing
  defdelegate at(image, coordinates), to: Drawing
  defdelegate clear(image, coordinates), to: Drawing
  defdelegate line(image, coordinates0, coordinates1, color \\ ExPng.Color.black()), to: Drawing

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
    {nil, update_in(image, [{x, y}], fn _ -> ExPng.Color.white() end)}
  end
end

defimpl Inspect, for: ExPng.Image do
  import Bitwise

  def inspect(%ExPng.Image{pixels: pixels}, _opts) do
    for line <- pixels do
      Enum.map(line, fn <<r, g, b, a>> ->
        pixel =
          ((r <<< 24) + (g <<< 16) + (b <<< 8) + a)
          |> Integer.to_string(16)
          |> String.downcase()
          |> String.pad_leading(8, "0")

        "0x" <> pixel
      end)
      |> Enum.join(" ")
    end
    |> Enum.join("\n")
  end
end
