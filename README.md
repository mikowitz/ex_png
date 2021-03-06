
<center>

![ExPng](priv/expng.png)

![Release](https://img.shields.io/github/v/tag/mikowitz/ex_png)
![Elixir](https://img.shields.io/badge/elixir-%3E%3D%201.7-blueviolet)
![UNLICENSE](https://img.shields.io/github/license/mikowitz/ex_png)
![CI Tests](https://github.com/mikowitz/ex_png/workflows/CI%20Tests/badge.svg)
![Credo](https://github.com/mikowitz/ex_png/workflows/Credo/badge.svg)
![Dialyzer](https://github.com/mikowitz/ex_png/workflows/Dialyzer/badge.svg)

</center>

ExPng is a pure Elixir implementation of the PNG image format. It can read and
write PNG files.

## Installation

Add `:ex_png` as a dependency in your project's `mix.exs`:

    def deps do
      [
        {:ex_png, "~> 1.0.0"}
      ]
    end

And run:

    ~$ mix deps.get

## Features

* Decodes any image the PNG standard allows. This includes all standard bit depths,
    color modes, filtering and iterlacing options
* Encodes using any options the PNG standard allows. See [Saving Images](#saving-images)
    below for the defaults `ExPng` uses, and how to override them
* Read/write access to the image's pixels
* Implements [Xiaolin Wu's algorithm][xw] for drawing antialiased lines
* Works with all Elixir versions >= 1.7

## Creating images

Images can be created by decoding an existing PNG file

    {:ok, image} = ExPng.Image.from_file("adorable_kittens.png")

by passing in a list of rows of `ExPng.Pixel` structs

    image = ExPng.Image.new([
        [ExPng.Pixel.rgb(100, 200, 200), ExPng.Pixel.rgb(0, 100, 100)],
        [ExPng.Pixel.rgb(50, 100, 200), ExPng.Pixel.rgb(0, 75, 43)],
    ])

or by creating a blank image with a given width and height

    image = ExPng.Image.new(200, 100)

## Modifying images

Images can be edited by painting/clearing individual pixels, drawing lines, or
erasing the entire canvas. These editing actions do not occur in layers, and
change the underlying pixels, so be careful as changes cannot be undone.

    image = ExPng.Image.new(32, 32)

    # Draws a pixel with the given color at the given coordinate
    image = ExPng.Image.draw(image, {5, 8}, ExPng.Pixel.rgb(0, 100, 200))

    # Draws a line between two points.
    image = ExPng.Image.line(image, {0, 0}, {15, 8}, ExPng.Pixel.black())

    # Sets a single pixel to opaque white
    image = ExPng.Image.clear(image, {0, 0})

    # Colors the entire canvas opaque white
    image = ExPng.Image.erase(image)

## Saving images

Images can be saved via

    ExPng.Image.to_file(image, filename)

When encoding images, `ExPng` will attempt to find the optimal bit depth and
color mode for the image in the following priority order:

1. pure black and white images
2. grayscale images, with or without transparency
3. color images where the number of unique colors is indexable
4. truecolor images with too many colors to index, with or without transparency

Filter type, compression level, and whether to encode the image with Adam7
interlacing can be set when saving an image:

    ExPng.Image.to_file(
        image,
        filename,
        filter: ExPng.Image.Filtering.sub,
        compression: 9,
        interlace: true
    )

Valid values for compression are integers 0 (no compression) through 9 (max compression).

Valid filter values are `.none`, `.up`, `.sub`, `.average`, and `.paeth`, which
can also be represented, respectively, by integers 0-5.

By default, `ExPng` uses the `up` filter, the default `zlib` compression
level 6, and no interlacing.

## Documentation

Complete documentation can be found on hexdocs.pm: [ExPng documentation][docs]

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
[hexdocs]: https://hexdocs.pm
[docs]: https://hexdocs.pm/ex_png/
