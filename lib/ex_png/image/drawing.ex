defmodule ExPng.Image.Drawing do
  @moduledoc """
  Utility module to hold functions related to drawing on images.
  """

  @type coordinate_pair :: {pos_integer, pos_integer}

  alias ExPng.{Color, Image}

  @doc """
  Colors the pixel at the given `{x, y}` coordinates in the image the provided
  color.
  """
  @spec draw(Image.t(), coordinate_pair, ExPng.maybe(Color.t())) :: Image.t()
  def draw(%Image{} = image, {_, _} = coordinates, color \\ Color.black()) do
    update_in(image, [coordinates], fn _ -> color end)
  end

  @doc """
  Returns the pixel at the given `{x, y}` coordinates in the image.
  """
  @spec at(Image.t(), coordinate_pair) :: Color.t()
  def at(%Image{} = image, {_, _} = coordinates) do
    get_in(image, [coordinates])
  end

  @doc """
  Clears the pixel at the given `{x, y}` coordinates in the image, coloring it
  opaque white.
  """
  @spec clear(Image.t(), coordinate_pair) :: Image.t()
  def clear(%Image{} = image, {_, _} = coordinates) do
    {nil, image} = pop_in(image, [coordinates])
    image
  end

  @doc """
  Erases all content in the image, setting every pixel to opaque white
  """
  @spec erase(Image.t()) :: Image.t()
  def erase(%Image{} = image) do
    %{image | pixels: build_pixels(image.width, image.height)}
  end

  defp build_pixels(width, height) do
    for _ <- 1..height do
      Stream.cycle([Color.white()]) |> Enum.take(width)
    end
  end

  @doc """
  Draws a line between the given coordinates in the image.

  Shortcut functions are provided for horizontal lines, vertical lines, and
  lines with a slope of 1 or -1. For other angles, [Xiaolin Wu's algorithm for
  drawing anti-aliased lines](https://en.wikipedia.org/wiki/Xiaolin_Wu%27s_line_algorithm) is used.
  """
  @spec line(Image.t(), coordinate_pair, coordinate_pair, ExPng.maybe(Color.t())) :: Image.t()
  def line(
        %Image{} = image,
        {x0, y0} = _coordinates0,
        {x1, y1} = _coordinates1,
        color \\ Color.black()
      ) do
    dx = x1 - x0
    dy = y1 - y0

    drawing_func =
      case {abs(dx), abs(dy)} do
        {_, 0} -> &draw_horizontal_line/6
        {0, _} -> &draw_vertical_line/6
        {d, d} -> &draw_diagonal_line/6
        _ -> &draw_line/6
      end

    drawing_func.(image, x0, y0, x1, y1, color)
  end

  defp draw_horizontal_line(%Image{} = image, x0, y, x1, y, color) do
    Enum.reduce(x0..x1, image, fn x, image ->
      draw(image, {x, y}, color)
    end)
  end

  defp draw_vertical_line(%Image{} = image, x, y0, x, y1, color) do
    Enum.reduce(y0..y1, image, fn y, image ->
      draw(image, {x, y}, color)
    end)
  end

  defp draw_diagonal_line(%Image{} = image, x0, y0, x1, y1, color) do
    dy = if y1 < y0, do: -1, else: 1

    {_, image} =
      Enum.reduce(x0..x1, {y0, image}, fn x, {y, image} ->
        {y + dy, draw(image, {x, y}, color)}
      end)

    image
  end

  defp draw_line(%Image{} = image, x0, y0, x1, y1, color) do
    steep = abs(y1 - y0) > abs(x1 - x0)

    [x0, y0, x1, y1] =
      case steep do
        true -> [y0, x0, y1, x1]
        false -> [x0, y0, x1, y1]
      end

    [x0, y0, x1, y1] =
      case x0 > x1 do
        true -> [x1, y1, x0, y0]
        false -> [x0, y0, x1, y1]
      end

    dx = x1 - x0
    dy = abs(y1 - y0)
    gradient = 1.0 * dy / dx

    {image, xpxl1, yend} = draw_end_point(image, x0, y0, gradient, steep, color)
    itery = yend + gradient

    {image, xpxl2, _} = draw_end_point(image, x1, y1, gradient, steep, color)

    {_, image} =
      Enum.reduce((xpxl1 + 1)..(xpxl2 - 1), {itery, image}, fn x, {itery, image} ->
        image =
          image
          |> put_color(x, ipart(itery), color, steep, rfpart(itery))
          |> put_color(x, ipart(itery) + 1, color, steep, fpart(itery))

        {itery + gradient, image}
      end)

    image
  end

  defp draw_end_point(image, x, y, gradient, steep, color) do
    xend = round(x)
    yend = y + gradient * (xend - x)
    xgap = rfpart(x + 0.5)
    xpxl = xend
    ypxl = ipart(yend)

    image =
      image
      |> put_color(xpxl, ypxl, color, steep, rfpart(yend) * xgap)
      |> put_color(xpxl, ypxl + 1, color, steep, fpart(yend) * xgap)

    {image, xpxl, yend}
  end

  defp put_color(image, x, y, color, steep, c) do
    [x, y] = if steep, do: [y, x], else: [x, y]
    draw(image, {round(x), round(y)}, anti_alias(color, at(image, {round(x), round(y)}), c))
  end

  defp anti_alias(color, old, ratio) do
    <<r, g, b, _>> = color
    <<old_r, old_g, old_b, _>> = old

    [r, g, b] =
      [r, g, b]
      |> Enum.zip([old_r, old_g, old_b])
      |> Enum.map(fn {n, o} -> round(n * ratio + o * (1.0 - ratio)) end)

    Color.rgb(r, g, b)
  end

  defp ipart(x), do: Float.floor(x)
  defp fpart(x), do: x - ipart(x)
  defp rfpart(x), do: 1.0 - fpart(x)
end
