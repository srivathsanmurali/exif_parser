defmodule ExifParser.Tag do
  @moduledoc """
  Tiff Tag parser. Parses the 12 bytes that represent the information contained
  in the TIFF tags.

  |           |         |
  |-----------|---------|
  | tag_id    | 2 bytes |
  | type_id   | 2 bytes |
  | tag_count | 4 bytes |
  | tag_vaue  | 4 bytes |
  
  The tag_id if referenced in the lookup table and tag_name field is updated
  with a more human readable atom value.

  The value is updated to the decoded value according to the data type.
  """
  
  defstruct tag_id: nil,
            tag_name: nil,
            data_type: nil,
            data_count: nil,
            value: nil

  @type t :: %__MODULE__{
          tag_id: non_neg_integer,
          tag_name: atom,
          data_type: Value.data_types(),
          data_count: non_neg_integer,
          value: any
        }

  defp value_offset_correction(value, tag_length, endian, start_of_tiff)
       when tag_length > 4 do
    value_offset = :binary.decode_unsigned(value, endian)

    <<_::binary-size(value_offset), new_value::binary-size(tag_length), _::binary>> =
      start_of_tiff

    new_value
  end

  defp value_offset_correction(value, _tag_length, _endian, _start_of_tiff) do
    value
  end

  @doc """
  The method parses the a binary buffer that contains a tag.

  + The tag_id, type_id and tag_count are decode by converting binary to integer.
  + The tag_id and tag_type is used to look up the tag_name.
  + The value of the tag is decoded using the type_id and tag_cousing the tag_type and tag_count.

  The tag_type is set to :tiff by default. 

  The result can be either a 
  {:ok, Tag} or {:error, String}
  """
  @spec parse(
          tag_buffer :: binary,
          endian :: :little | :big,
          start_of_tiff :: non_neg_integer,
          tag_type :: ExifParser.Tag.LookUp.tag_type()
        ) :: {:ok, __MODULE__} | {:error, String.t()}

  def parse(tag_buffer, header, start_of_tiff, tag_type \\ :tiff)

  def parse(
        <<tag_id::binary-size(2), type_id::binary-size(2), tag_count::binary-size(4),
          value::binary-size(4)>>,
        endian,
        start_of_tiff,
        tag_type
      ) do
    tag_id= :binary.decode_unsigned(tag_id, endian)

    data_type =
      :binary.decode_unsigned(type_id, endian)
      |> ExifParser.Tag.Value.type_id_to_data_type()

    tag_count = :binary.decode_unsigned(tag_count, endian)
    tag_length = ExifParser.Tag.Value.data_type_to_byte_length(data_type, tag_count)

    value = value_offset_correction(value, tag_length, endian, start_of_tiff)

    %__MODULE__{tag_id: tag_id, data_type: data_type, data_count: tag_count, value: value}
    |> ExifParser.Tag.LookUp.look_up_name(tag_type)
    |> ExifParser.Tag.Value.decode_tag(endian)
    |> parse_sub_ifd(start_of_tiff, endian)
  end

  def parse(_, _, _, _), do: {}

  defp parse_sub_ifd(
         %__MODULE__{tag_name: tag_name, value: sub_ifd_offset} = tag,
         start_of_tiff,
         endian
       )
       when tag_name in [:exif, :gps, :interoperability] do
    [sub_ifd | []]=
      ExifParser.ImageFileDirectory.parse_ifds(
        endian,
        start_of_tiff,
        sub_ifd_offset,
        tag_name
      )

    %__MODULE__{tag | value: sub_ifd}
  end
  defp parse_sub_ifd(tag,_,_), do: tag
end
