defmodule ExifParser.Header do
  @moduledoc """
  Tiff header parser. Parses the 8 byte TIFF header that provides the information
  needed to decode the TIFF tags.

  ## Struct
  ### identifier
  The endianess of the binary file is given by the first 2 bytes of the header.

  returns 
  ```
  :little | :big
  ```
  ### version
  In a valid parser and file, the second 2 bytes should correspond to the value 42.

  The version is always 42.
  This is sanity check.

  ### ifd_offset
  The last 4 bytes of the header provide the offset to the first IFD.
  """
  defstruct identifier: nil,
            version: nil,
            ifd_offset: nil

  @litte_endian_identifier 0x4949
  @big_endian_identifier 0x4D4D

  @doc """
  TIFF Header parser

  This method parses the tiff header and returns the ExifParser.Header.
  """
  def parse(<<@litte_endian_identifier::16, forty_two::binary-size(2), offset::binary-size(4)>>) do
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

  def parse(<<@big_endian_identifier::16, forty_two::binary-size(2), offset::binary-size(4)>>) do
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
