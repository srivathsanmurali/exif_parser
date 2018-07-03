defmodule TiffParser.Header do
  defstruct identifier: nil,
            version: nil,
            ifd_offset: nil

  @litte_endian_identifier 0x4949
  @big_endian_identifier 0x4D4D

  def parse(
        <<@litte_endian_identifier::16, forty_two::binary-size(2), offset::binary-size(4)>>
      ) do
    with 42 <- :binary.decode_unsigned(forty_two, :little),
         offset <- :binary.decode_unsigned(offset, :little) do
      {:ok,
       %__MODULE__{
         identifier: :little,
         version: 42,
         ifd_offset: offset
       }}
    else
      _err -> {:error, "Can't parse TiffHeader"}
    end
  end

  def parse(
        <<@big_endian_identifier::16, forty_two::binary-size(2), offset::binary-size(4)>>
      ) do
    with 42 <- :binary.decode_unsigned(forty_two, :big),
         offset <- :binary.decode_unsigned(offset, :big) do
      {:ok,
       %__MODULE__{
         identifier: :big,
         version: 42,
         ifd_offset: offset
       }}
    else
      _err -> {:error, "Can't parse TiffHeader"}
    end
  end
end
