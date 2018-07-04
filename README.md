# ExifParser

Parse EXIF/TIFF metadata from JPEG and TIFF files.
Exif/TIFF referes to the metadata added to jpeg images. It is encoded as part of the jpeg file.

There are multiple so-called "Image File Directories" or IFD that store information about the image.
+ IFD0 generally stores the image, EXIF and GPS metadata
+ IFD1 when available stores the information about a thumbnail image.

## Usage

### Read from jpeg file
Read data from a binary jpeg file.

```elixir
iex(1)> {:ok, tags} = ExifParser.parse_jpeg_file("/path/to/file.jpg")
{:ok,
 %{
   ifd0: %{
     date_time: "2008:07:31 10:05:49",
     exif: %{color_space: 1, pixel_x_dimension: 100, pixel_y_dimension: 77},
     orientation: 1,
     resolution_unit: 2,
     software: "GIMP 2.4.5",
     x_resolution: 300.0,
     y_resolution: 300.0
   },
   ifd1: %{
     compression: 6,
     jpeg_interchange_format: 282,
     jpeg_interchange_format_length: 2022,
     resolution_unit: 2,
     x_resolution: 72.0,
     y_resolution: 72.0
   }
 }}
```

A specific tag data can be retrived by 
```elixir
iex(2)> tags.ifd0.date_time
"2008:07:31 10:05:49"
iex(3)> tags.ifd0.exif.color_space
1
```

### Read from tiff file
Data can also be read from binary tiff files.

```elixir
iex(2)> {:ok, tags} = ExifParser.parse_tiff_file("/home/sri/exif_tests/test1.tiff")
{:ok,
 %{
   ifd0: %{
     bits_per_sample: '\b\b\b\b',
     compression: 5,
     extra_samples: 1,
     image_length: 38,
     image_width: 174,
     orientation: 1,
     photometric_interpretation: 2,
     planar_configuration: 1,
     predictor: 2,
     rows_per_strip: 38,
     sample_format: [1, 1, 1, 1],
     samples_per_pixel: 4,
     strip_byte_counts: 6391,
     strip_offsets: 8
}}
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `exif_parser` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:exif_parser, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/exif_parser](https://hexdocs.pm/exif_parser).

