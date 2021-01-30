# ex_png

![CI Tests](https://github.com/mikowitz/ex_png/workflows/CI%20Tests/badge.svg)
![Credo](https://github.com/mikowitz/ex_png/workflows/Credo/badge.svg)

ExPng is a pure Elixir implementation of the PNG image format. It can read and
write PNG files.

## Installation

Add `:ex_png` as a dependency in your project's `mix.exs`:

    def deps do
      [
        {:ex_png, "~> 0.1.0"}
      ]
    end

And run:

    ~$ mix deps.get

## Features

* Decodes any image the PNG standard allows. This includes all standard bit depths,
    color modes, filtering and iterlacing options.
* Encodes using 8 bit depth, truecolor alpha color mode, default zlib compression,
    and no interlacing. Eventually `ExPng` will be able to choose encoding
    parameters based on the nature of the image (See [Issue #11][i11])
* Read/write access to the image's pixels
* Implements [Xiaolin Wu's algorithm][xw] for drawing antialiased lines
* Works with all Elixir versions >= 1.7


## Creating images

Images can be created by decoding an existing PNG file

    {:ok, image} = ExPng.Image.from_file("adorable_kittens.png")

or by creating a blank image with a given width and height

    image = ExPng.Image.new(200, 100)

## Modifying images

Images can be edited by painting/clearing individual pixels, drawing lines, or
erasing the entire canvas. These editing actions do not occur in layers, and
change the underlying pixels, so be careful as changes cannot be undone.

    {:ok, image} = ExPng.Image.from_file("adorable_kittens.png")

    # Draws a pixel with the given color at the given coordinate
    image = ExPng.Image.draw(image, {5, 8}, ExPng.Pixel.rgb(100, 100, 200))

    # Draws a line between two points.
    image = ExPng.Image.line(image, {0, 0}, {15, 8}, ExPng.Pixel.black())

    # Sets a single pixel to opaque white
    image = ExPng.Image.clear(image, {7, 3})

    # Colors the entire canvas opaque white
    image = ExPng.Image.erase(image)

## Saving images

Images can be saved via

    ExPng.Image.to_file(filename)

## About

This library is written by Michael Berkowitz and released under the [UNLICENSE](UNLICENSE).

The suite of test images in [test/png_suite](test/png_suite) comes from
Willem van Schaik's [PngSuite][pngsuite], with some additions made by
Willem van Bergen as part of his work on [ChunkyPNG][chunky], and some added
by the author of this library.

[xw]: https://en.wikipedia.org/wiki/Xiaolin_Wu%27s_line_algorithm
[i11]: https://github.com/mikowitz/ex_png/issues/11
[pngsuite]: http://www.schaik.com/pngsuite/
[chunky]: https://github.com/wvanbergen/chunky_png
