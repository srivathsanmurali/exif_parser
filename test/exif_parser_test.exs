defmodule ExifParserTest do
  # use ExUnit.Case
  # doctest ExifParser

  # You can get this file by downloading and unzipping this file:
  # https://aeronav.faa.gov/visual/12-02-2021/sectional-files/Kansas_City.zip
  {:ok, tags} = ExifParser.parse_tiff_file("Kansas City SEC.tif")
  IO.inspect(tags)
end
