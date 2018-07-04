defmodule ExifParser.Pretty do
  alias ExifParser.ImageFileDirectory
  alias ExifParser.Tag

  def prettify(ifds) do
    Enum.map(ifds, &make_pretty/1)
  end

  defp make_pretty({ifd_id, %ImageFileDirectory{tag_lists: tag_lists}}),
    do: {ifd_id, Enum.map(tag_lists, &make_pretty/1)}

  defp make_pretty({tag_id, %Tag{value: value}}),
    do: {tag_id, make_pretty(value)}
  
  defp make_pretty(%ImageFileDirectory{tag_lists: tag_lists}),
    do: Enum.map(tag_lists, &make_pretty/1)
  
  defp make_pretty(%Tag{value: value}),
    do: make_pretty(value)

  defp make_pretty(x), do: x
end
