defmodule TiffParser.Tag do
  defstruct tag_id: nil,
            data_type: nil,
            data_count: nil,
            value: nil

  @type data_types ::
          :tiff_byte
          | :tiff_ascii
          | :tiff_short
          | :tiff_long
          | :tiff_rational
          | :tiff_sbyte
          | :tiff_undefined
          | :tiff_sshort
          | :tiff_slong
          | :tiff_srational
          | :tiff_sfloat
          | :tiff_dfloat

  @type t :: %__MODULE__{
          tag_id: non_neg_integer,
          data_type: data_types,
          data_count: non_neg_integer,
          value: any
        }
  def type_id_to_data_type(1), do: :tiff_byte
  def type_id_to_data_type(2), do: :tiff_ascii
  def type_id_to_data_type(3), do: :tiff_short
  def type_id_to_data_type(4), do: :tiff_long
  def type_id_to_data_type(5), do: :tiff_rational
  def type_id_to_data_type(6), do: :tiff_sbyte
  def type_id_to_data_type(7), do: :tiff_undefined
  def type_id_to_data_type(8), do: :tiff_sshort
  def type_id_to_data_type(9), do: :tiff_slong
  def type_id_to_data_type(10), do: :tiff_srational
  def type_id_to_data_type(11), do: :tiff_sfloat
  def type_id_to_data_type(12), do: :tiff_dfloat

  defp data_type_to_byte_length(:tiff_byte, component_count ), do: component_count
  defp data_type_to_byte_length(:tiff_ascii, component_count ), do: component_count
  defp data_type_to_byte_length(:tiff_short, component_count ), do: 2 * component_count
  defp data_type_to_byte_length(:tiff_long, component_count ), do: 4 * component_count
  defp data_type_to_byte_length(:tiff_rational, component_count ), do: 8 * component_count
  defp data_type_to_byte_length(:tiff_undefined, component_count ), do: component_count
  defp data_type_to_byte_length(:tiff_sshort, component_count ), do: 2 * component_count
  defp data_type_to_byte_length(:tiff_slong, component_count ), do: 4 * component_count
  defp data_type_to_byte_length(:tiff_srational, component_count ), do: 8 * component_count
  defp data_type_to_byte_length(:tiff_sfloat, component_count ), do: 4 * component_count
  defp data_type_to_byte_length(:tiff_dfloat, component_count ), do: 8 * component_count

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
    data_type = :binary.decode_unsigned(type_id, endian) |> type_id_to_data_type()
    tag_count = :binary.decode_unsigned(tag_count, endian)
    tag_length = data_type_to_byte_length(data_type, tag_count)

    value =
      if tag_length > 4 do
        value_offset = :binary.decode_unsigned(value, endian)

        <<_::binary-size(value_offset), new_value::binary-size(tag_length), _::binary>> =
          start_of_tiff

        new_value
      else
        value
      end

    %__MODULE__{tag_id: tag_id,
            data_type: data_type,
            data_count: tag_count,
            value: value}
  end
  def parse(_,_,_), do: {}
end
