defmodule ExifParser.Pretty do
  @moduledoc """
  The module provides a simple function to make the output pretty.
  This removes all the data that is read as part of the parsing.

  It returns the tags as a nested map structure. This makes is really easy to use.
  """
  alias ExifParser.ImageFileDirectory
  alias ExifParser.Tag

  @doc """
  Calling prettify on map of ifds, will remove all the extra information around the IFD and Tag structures.
  """
  def prettify(ifds) do
    Enum.map(ifds, &make_pretty/1) |> Enum.into(Map.new())
  end

  defp make_pretty({ifd_id, %ImageFileDirectory{tag_lists: tag_lists}}),
    do: {ifd_id, Enum.map(tag_lists, &make_pretty/1) |> Enum.into(Map.new())}

  defp make_pretty({tag_name, %Tag{value: value}}), do: {tag_name, make_pretty(value)}

  defp make_pretty(%ImageFileDirectory{tag_lists: tag_lists}),
    do: Enum.map(tag_lists, &make_pretty/1) |> Enum.into(Map.new())

  defp make_pretty(%Tag{value: value}), do: make_pretty(value)

  defp make_pretty(x), do: x
end
