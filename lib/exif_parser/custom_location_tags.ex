defmodule ExifParser.CustomLocationTag do
  alias ExifParser.Tag

  @doc """
    Parses tags from at custom tag locations in the memory.
    Some manufacturers add custom tags at specific memory locations.
    It can be easily read using this function.

    I know this is a bad way of accessing stuff. Hence, its an option. 
    Sometimes you just can't choose how you get your data. :(
  """
  def parse_custom_tags(tag_offsets_and_names, endian, buffer, prettify \\ true)

  def parse_custom_tags(nil, _endian, _buffer, _prettify) do
    nil
  end

  def parse_custom_tags(tag_offsets_and_names, endian, buffer, false) do
    tag_offsets_and_names
    |> Enum.reduce(Map.new(), fn {tag_offset, tag_name}, acc ->
      tag = parse_custom_tag(tag_offset, endian, buffer)
      tag = %Tag{tag | tag_name: tag_name}
      Map.put(acc, tag_name, tag)
    end)
  end

  def parse_custom_tags(tag_offsets_and_names, endian, buffer, true) do
    parse_custom_tags(tag_offsets_and_names, endian, buffer, false)
    |> ExifParser.Pretty.prettify()
  end

  defp parse_custom_tag(
         tag_offset,
         endian,
         buffer
       )
       when not is_list(tag_offset) do
    <<_::binary-size(tag_offset), tag_buffer::binary-size(12), _::binary>> = buffer
    ExifParser.Tag.parse(tag_buffer, endian, buffer)
  end
end
