defmodule TiffParser.ImageFileDirectory do
  defstruct num_entries: nil,
            tag_lists: %{},
            offset: nil

  alias TiffParser.Tag

  def parse_ifds(header, start_of_tiff, offset) do
    find_ifds(header, start_of_tiff, offset)
    |> Enum.map(&parse_tags(&1, header, start_of_tiff))
  end

  defp find_ifds(_, _, 0) do
    []
  end

  defp find_ifds(%TiffParser.Header{identifier: endian} = header, start_of_tiff, offset) do
    <<_::binary-size(offset), num_entries::binary-size(2), _rest::binary>> = start_of_tiff
    num_entries = :binary.decode_unsigned(num_entries, endian)
    ifd_byte_size = num_entries * 12

    # parse ifd
    <<_::binary-size(offset), _num_entries::binary-size(2),
      ifd_buffer::binary-size(ifd_byte_size), next_ifd_offset::binary-size(4),
      _rest::binary>> = start_of_tiff

    next_ifd_offset = :binary.decode_unsigned(next_ifd_offset, endian)

    [%__MODULE__{num_entries: num_entries, offset: ifd_buffer}] ++
      find_ifds(header, start_of_tiff, next_ifd_offset)
  end

  defp parse_tags(
         %__MODULE__{offset: ifd_offset, num_entries: num_entries},
         header,
         start_of_tiff
       ) do
    tag_lists =
      0..(num_entries - 1)
      |> Enum.reduce(Map.new(), fn x, acc ->
        tag_offset = x * 12
        <<_::binary-size(tag_offset), tag_buffer::binary-size(12), _rest::binary>> = ifd_offset
        tag = Tag.parse(tag_buffer, header, start_of_tiff)
        Map.put(acc, tag.tag_id, tag)
      end)

    %__MODULE__{offset: nil, tag_lists: tag_lists, num_entries: num_entries}
  end
end
