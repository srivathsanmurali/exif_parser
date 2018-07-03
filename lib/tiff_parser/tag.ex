defmodule TiffParser.Tag do
  defstruct tag_id: nil,
            data_type: nil,
            data_count: nil,
            value: nil

  @type t :: %__MODULE__{
          tag_id: non_neg_integer,
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

  @spec parse(
          tag_buffer :: binary,
          endian :: :little | :big,
          start_of_tiff :: non_neg_integer,
          tag_type :: TiffParser.Tag.LookUp.tag_type()
        ) :: {:ok, __MODULE__} | {:error, String.t()}

  def parse(tag_buffer, header, start_of_tiff, tag_type \\ :tiff)

  def parse(
        <<tag_id::binary-size(2), type_id::binary-size(2), tag_count::binary-size(4),
          value::binary-size(4)>>,
        endian,
        start_of_tiff,
        tag_type
      ) do
    tag_id = :binary.decode_unsigned(tag_id, endian)

    data_type =
      :binary.decode_unsigned(type_id, endian)
      |> TiffParser.Tag.Value.type_id_to_data_type()

    tag_count = :binary.decode_unsigned(tag_count, endian)
    tag_length = TiffParser.Tag.Value.data_type_to_byte_length(data_type, tag_count)

    value = value_offset_correction(value, tag_length, endian, start_of_tiff)

    %__MODULE__{tag_id: tag_id, data_type: data_type, data_count: tag_count, value: value}
    |> TiffParser.Tag.LookUp.look_up_name(tag_type)
    |> TiffParser.Tag.Value.decode_tag(endian)
    |> parse_sub_ifd(start_of_tiff, endian)
  end

  def parse(_, _, _, _), do: {}

  defp sub_ifd_tag_to_type(:exif_sub_ifd), do: :exif
  defp sub_ifd_tag_to_type(:gps_sub_ifd), do: :gps
  defp sub_ifd_tag_to_type(:interoperability_sub_ifd), do: :interop

  defp parse_sub_ifd(
         %__MODULE__{tag_id: tag_id, value: sub_ifd_offset} = tag,
         start_of_tiff,
         endian
       )
       when tag_id in [:exif_sub_ifd, :gps_sub_ifd, :interoperability_sub_ifd] do
    sub_ifd =
      TiffParser.ImageFileDirectory.parse_ifds(
        endian,
        start_of_tiff,
        sub_ifd_offset,
        sub_ifd_tag_to_type(tag_id)
      )

    %__MODULE__{tag | value: sub_ifd}
  end
  defp parse_sub_ifd(tag,_,_), do: tag
end
