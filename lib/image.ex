defmodule ExPng.Image do
  defstruct [
    :header,
    :data,
    :palette,
    :end,
    :ancillary_chunks
  ]

  def from_chunks(header_chunk, chunks) do
    with {:ok, data_chunks, chunks} <- find_image_data(chunks),
         {:ok, end_chunk, chunks} <- find_end(chunks),
         {:ok, palette, chunks} <- find_palette(chunks, header_chunk)
    do
      {
        :ok,
        %__MODULE__{
          header: header_chunk,
          data: data_chunks,
          palette: palette,
          end: end_chunk,
          ancillary_chunks: chunks
        }
      }
    else
      {:error, error} -> {:error, error}
    end
  end

  def find_image_data(chunks) do
    case Enum.split_with(chunks, &(&1.type == "IDAT")) do
      {[], _} -> {:error, "missing IDAT chunks"}
      {image_data, chunks} -> {:ok, image_data, chunks}
    end
  end

  def find_end(chunks) do
    case Enum.find(chunks, &(&1.type == "IEND")) do
      nil -> {:error, "missing IEND chunk"}
      chunk -> {:ok, chunk, Enum.reject(chunks, fn c -> c == chunk end)}
    end
  end

  def find_palette(chunks, %{color_type: color_type}) do
    case {Enum.find(chunks, &(&1.type == "PLTE")), color_type} do
      {nil, 3} -> {:error, "missing PLTE for color type 3"}
      {plt, ct} when not is_nil(plt) and ct in [0, 4] -> {:error, "PLTE present for grayscale image"}
      {plt, _} -> {:ok, plt, Enum.reject(chunks, fn c -> c == plt end)}
    end
  end
end
