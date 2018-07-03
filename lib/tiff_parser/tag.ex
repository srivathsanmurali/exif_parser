defmodule TiffParser.Tag do
  defstruct tag_id: nil,
            data_type: nil,
            data_count: nil,
            value: nil

  @type t :: %__MODULE__{
          tag_id: non_neg_integer,
          data_type: Value.data_types,
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
          tiff_header :: TiffParser.Header,
          start_of_tiff :: non_neg_integer
        ) :: {:ok, __MODULE__} | {:error, String.t()}
  def parse(
        <<tag_id::binary-size(2), type_id::binary-size(2), tag_count::binary-size(4),
          value::binary-size(4)>>,
        %{identifier: endian},
        start_of_tiff
      ) do
    tag_id = :binary.decode_unsigned(tag_id, endian)
    data_type =
      :binary.decode_unsigned(type_id, endian)
      |> TiffParser.Tag.Value.type_id_to_data_type()
    tag_count = :binary.decode_unsigned(tag_count, endian)
    tag_length = 
      TiffParser.Tag.Value.data_type_to_byte_length(data_type, tag_count)

    value = 
      value_offset_correction(value, tag_length, endian, start_of_tiff)

    %__MODULE__{tag_id: tag_id,
            data_type: data_type,
            data_count: tag_count,
            value: value}
      |> TiffParser.Tag.LookUp.look_up_name()
      |> TiffParser.Tag.Value.decode_tag(endian)
  end
  def parse(_,_,_), do: {}
end
