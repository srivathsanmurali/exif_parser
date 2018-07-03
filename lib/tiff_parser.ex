defmodule TiffParser do
  @max_length 2*(65536+2)

  alias TiffParser.Header
  alias TiffParser.ImageFileDirectory, as: IFD
  
  def parse_tiff_file(filepath) do
    {:ok, buffer} = File.open(filepath, [:read], &(IO.binread(&1, @max_length)))
    parse_tiff_binary(buffer)
  end

  def parse_tiff_binary(
    <<header :: binary-size(8), _rest :: binary>> = start_of_tiff) do
    with {:ok, header} <- Header.parse(header),
         ifds <- IFD.parse_ifds(header, start_of_tiff, header.ifd_offset)
    do
      {:ok, ifds}
    else
      err -> err
    end
  end
end
