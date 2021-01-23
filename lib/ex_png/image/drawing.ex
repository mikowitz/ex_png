defmodule ExPng.Image.Drawing do
  @moduledoc false

  alias ExPng.Image

  def draw_horizontal_line(%Image{} = image, x0, y, x1, y, color) do
    Enum.reduce(x0..x1, image, fn x, image ->
      draw(image, [x, y], color)
    end)
  end

  def draw_vertical_line(%Image{} = image, x, y0, x, y1, color) do
    Enum.reduce(y0..y1, image, fn y, image ->
      draw(image, [x, y], color)
    end)
  end

  def draw_diagonal_line(%Image{} = image, x0, y0, x1, y1, color) do
    dy = if y1 < y0, do: -1, else: 1

    {_, image} =
      Enum.reduce(x0..x1, {y0, image}, fn x, {y, image} ->
        {y + dy, draw(image, [x, y], color)}
      end)

    image
  end

  def draw_line(%Image{} = image, x0, y0, x1, y1, color) do
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

  def put_color(image, x, y, color, steep, c) do
    [x, y] = if steep, do: [y, x], else: [x, y]
    draw(image, [x, y], anti_alias(color, at(image, [x, y]), c))
  end

  def anti_alias(color, old, ratio) do
    [r, g, b] =
      [color.r, color.g, color.b]
      |> Enum.zip([old.r, old.g, old.b])
      |> Enum.map(fn {n, o} -> round(n * ratio + o * (1.0 - ratio)) end)

    ExPng.Pixel.rgb(r, g, b)
  end

  def ipart(x), do: Float.floor(x)
  def fpart(x), do: x - ipart(x)
  def rfpart(x), do: 1.0 - fpart(x)

  def draw(%Image{} = image, [x, y], pixel) do
    update_in(image, [{x, y}], fn _ -> pixel end)
  end

  def at(%Image{} = image, [x, y]) do
    get_in(image, [{x, y}])
  end

  def clear(%Image{} = image, [x, y]) do
    pop_in(image, [{x, y}])
  end
end
