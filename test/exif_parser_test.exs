defmodule ExifParserTest do
  # use ExUnit.Case
  # doctest ExifParser

  {:ok, tags} = ExifParser.parse_tiff_file("../../flightsystems/charts/Kansas City SEC.tif")
  IO.inspect(tags)
end
