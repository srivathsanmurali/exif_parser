defmodule ExifParser.Tag.Value do
  alias ExifParser.Tag

  # 2^31
  @max_signed_32_bit_int 2_147_483_648
  # 2^15
  @max_signed_16_bit_int 632_768

  @typedoc """
    The data types that are represented in TIFF tags.
  """
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

  @doc """
  The method provides the lookup for the 12 data_types.
  The data_type can inferred from the type_id in the tag buffer.
  """
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

  @doc """
  The method provides the number of bytes that correspond to the data type.
  It will give the number of bytes for number of components in the tag.
  """
  def data_type_to_byte_length(data_type, component_count \\ 1)
  def data_type_to_byte_length(:tiff_byte, component_count), do: component_count
  def data_type_to_byte_length(:tiff_ascii, component_count), do: component_count
  def data_type_to_byte_length(:tiff_short, component_count), do: 2 * component_count
  def data_type_to_byte_length(:tiff_sshort, component_count), do: 2 * component_count
  def data_type_to_byte_length(:tiff_long, component_count), do: 4 * component_count
  def data_type_to_byte_length(:tiff_slong, component_count), do: 4 * component_count
  def data_type_to_byte_length(:tiff_rational, component_count), do: 8 * component_count
  def data_type_to_byte_length(:tiff_srational, component_count), do: 8 * component_count
  def data_type_to_byte_length(:tiff_undefined, component_count), do: component_count
  def data_type_to_byte_length(:tiff_sfloat, component_count), do: 4 * component_count
  def data_type_to_byte_length(:tiff_dfloat, component_count), do: 8 * component_count

  # defp decode_numeric(value, component_count, size, endian) do
  defp decode_numeric(value, 1, type_size, endian) do
    <<data::binary-size(type_size), _::binary>> = value
    :binary.decode_unsigned(data, endian)
  end

  defp decode_numeric(value, data_count, type_size, endian) do
    decode_many_numeric(value, data_count, type_size, endian)
  end

  defp decode_many_numeric(_value, 0, _type_size, _endian), do: []

  defp decode_many_numeric(value, data_count, type_size, endian) do
    <<data::binary-size(type_size), rest::binary>> = value

    [
      :binary.decode_unsigned(data, endian)
      | decode_many_numeric(rest, data_count - 1, type_size, endian)
    ]
  end

  defp maybe_signed_int(x, signed, max_val \\ @max_signed_32_bit_int)
  defp maybe_signed_int(x, :signed, max_val) when x > max_val, do: x - max_val - 1

  defp maybe_signed_int(x, _, _), do: x

  defp decode_rational(value, data_count, endian, signed \\ :unsigned)

  defp decode_rational(value, 1, endian, signed) do
    <<numerator::binary-size(4), denominator::binary-size(4), _rest::binary>> = value
    numerator = :binary.decode_unsigned(numerator, endian) |> maybe_signed_int(signed)
    denominator = :binary.decode_unsigned(denominator, endian) |> maybe_signed_int(signed)

    if denominator == 0 do
      0
    else
      numerator / denominator
    end
  end

  defp decode_rational(value, data_count, endian, signed) do
    decode_many_rational(value, data_count, endian, signed)
  end

  defp decode_many_rational(value, data_count, endian, signed) do
    <<rational::binary-size(8), rest::binary>> = value

    [
      decode_rational(rational, 1, endian, signed)
      | decode_many_rational(rest, data_count - 1, endian, signed)
    ]
  end

  @doc """
  The method is used to decode the binary value in the tag buffer based on the data_type
  and endianess of the file.

  The total data size is computed based on the type size and the number of components.

  + If the data_size is less or equal to 4 bytes, the value binary represents the actual value.
  + If the data_size is greater than 4, the binary value represents the offset in
  the file buffer that points to the actual data.
  """
  @spec decode_tag(tag :: Tag, endian :: :little | :big) :: Tag
  def decode_tag(%Tag{data_type: :tiff_byte, data_count: data_count, value: value} = tag, endian),
    do: %Tag{tag | value: decode_numeric(value, data_count, 1, endian)}

  def decode_tag(
        %Tag{data_type: :tiff_ascii, data_count: data_count, value: value} = tag,
        _endian
      ) do
    string_size = data_count - 1
    <<string::binary-size(string_size), _null::binary>> = value
    %Tag{tag | value: string}
  end

  def decode_tag(%Tag{data_type: :tiff_short, data_count: data_count, value: value} = tag, endian),
    do: %Tag{tag | value: decode_numeric(value, data_count, 2, endian)}

  def decode_tag(
        %Tag{data_type: :tiff_sshort, data_count: data_count, value: value} = tag,
        endian
      ),
      do: %Tag{
        tag
        | value:
            decode_numeric(value, data_count, 2, endian)
            |> maybe_signed_int(:signed, @max_signed_16_bit_int)
      }

  def decode_tag(%Tag{data_type: :tiff_long, data_count: data_count, value: value} = tag, endian),
    do: %Tag{tag | value: decode_numeric(value, data_count, 4, endian)}

  def decode_tag(%Tag{data_type: :tiff_slong, data_count: data_count, value: value} = tag, endian),
    do: %Tag{
      tag
      | value: decode_numeric(value, data_count, 4, endian) |> maybe_signed_int(:signed)
    }

  def decode_tag(
        %Tag{data_type: :tiff_rational, data_count: data_count, value: value} = tag,
        endian
      ),
      do: %Tag{tag | value: decode_rational(value, data_count, endian)}

  def decode_tag(
        %Tag{data_type: :tiff_srational, data_count: data_count, value: value} = tag,
        endian
      ),
      do: %Tag{tag | value: decode_rational(value, data_count, endian, :signed)}

  def decode_tag(
        %Tag{data_type: :tiff_undefined, data_count: data_count, value: value} = tag,
        endian
      ),
      do: %Tag{tag | value: decode_numeric(value, data_count, 1, endian)}

  def decode_tag(tag, _), do: tag
end
