defmodule ExifParser.ImageFileDirectory do
  @moduledoc """
  Tiff Image File Directory parser. Parses the IFD that provides the number of
  tags in the IFD and offset from the start of the file buffer.

  ## Struct
  ### num_entries
  The length of the IFD desciptor helps in parsing the IFD.
  This can be used to find the end of the IFD.

  ### tag_lists
  This holds the map of tags. The keys in the map are tag_names and the values
  are tag_values.

  ### offset
  This represents the non-neg-integer that gives the number of bytes offset from
  the start of tiff buffer.
  """
  defstruct num_entries: nil,
            tag_lists: %{},
            offset: nil

  @type t :: %__MODULE__{
    num_entries: non_neg_integer,
    tag_lists: map,
    offset: non_neg_integer
  }

  alias ExifParser.Tag

  @doc """
  The IFDs are parsed from the tiff buffer. The map keys for the IFDs are updated
  and prettified if passed as argument.

  The output is made pretty by default.
  """
  @spec parse_tiff_body(
          endian :: :little | :big,
          start_of_tiff :: binary,
          offset :: non_neg_integer,
          prettify :: Boolean
        ) :: %{atom: __MODULE__}
  def parse_tiff_body(endian, start_of_tiff, offset, prettify \\ true)

  def parse_tiff_body(endian, start_of_tiff, offset, false) do
    parse_ifds(endian, start_of_tiff, offset, :tiff)
    |> name_primary_ifds()
  end

  def parse_tiff_body(endian, start_of_tiff, offset, true) do
    parse_tiff_body(endian, start_of_tiff, offset, false)
    |> ExifParser.Pretty.prettify()
  end

  @doc """
  This method parses the ifds that are reachable, given the endianess, tiff_buffer,
  and the offset.

  The IFD are first found and the tags in each of them parsed.
  """
  @spec parse_ifds(
          endian :: :little | :big,
          start_of_tiff :: binary,
          offset :: non_neg_integer,
          tag_type :: ExifParser.Tag.LookUp.tag_type()
        ) :: [__MODULE__]
  def parse_ifds(endian, start_of_tiff, offset, tag_type) do
    find_ifds(endian, start_of_tiff, offset)
    |> Enum.map(&parse_tags(&1, endian, start_of_tiff, tag_type))
  end

  defp name_primary_ifds(ifds) do
    ifds
    |> Stream.with_index()
    |> Enum.reduce(Map.new(), fn {ifd, k}, acc ->
      Map.put(acc, String.to_atom("ifd#{k}"), ifd)
    end)
  end

  defp find_ifds(_, _, 0) do
    []
  end

  defp find_ifds(endian, start_of_tiff, offset) do
    <<_::binary-size(offset), num_entries::binary-size(2), _rest::binary>> = start_of_tiff
    num_entries = :binary.decode_unsigned(num_entries, endian)
    ifd_byte_size = num_entries * 12

    # parse ifd
    <<_::binary-size(offset), _num_entries::binary-size(2),
      ifd_buffer::binary-size(ifd_byte_size), next_ifd_offset::binary-size(4),
      _rest::binary>> = start_of_tiff

    next_ifd_offset = :binary.decode_unsigned(next_ifd_offset, endian)

    [
      %__MODULE__{num_entries: num_entries, offset: ifd_buffer}
      | find_ifds(endian, start_of_tiff, next_ifd_offset)
    ]
  end

  defp parse_tags(%__MODULE__{num_entries: 0}, _endian, _start, _tag_type), do: nil

  defp parse_tags(
         %__MODULE__{offset: ifd_offset, num_entries: num_entries},
         endian,
         start_of_tiff,
         tag_type
       ) do
    tag_lists =
      0..(num_entries - 1)
      |> Enum.reduce(Map.new(), fn x, acc ->
        tag_offset = x * 12
        <<_::binary-size(tag_offset), tag_buffer::binary-size(12), _rest::binary>> = ifd_offset
        tag = Tag.parse(tag_buffer, endian, start_of_tiff, tag_type)
        Map.put(acc, tag.tag_name, tag)
      end)

    %__MODULE__{offset: ifd_offset, num_entries: num_entries, tag_lists: tag_lists}
  end
end
