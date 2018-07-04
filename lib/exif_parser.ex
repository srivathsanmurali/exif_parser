defmodule ExifParser do
  @max_length 2 * (65536 + 2)

  # jpeg constants
  @jpeg_start_of_image 0xFFD8
  @jpeg_app1 0xFFE1

  alias ExifParser.Header
  alias ExifParser.ImageFileDirectory, as: IFD
  alias ExifParser.CustomLocationTag, as: CLT

  defmodule Options do
    @moduledoc """
    Options that are passed to the API.
    Currently only two options are used.
    
    # prettify
      This enables makes the tag output pretty.
      The values can be set to false to get data used to parse.
        
      **Default: true**


    # tag_offsets_and_names
      This lets the user parse custom tags at custom memory locations.
      
      %ExifParser.Options {
        tag_offsets_and_names: [{MEMORY_LOCATION, :custom_tag_name}]
      }
    """
    defstruct prettify: true,
              tag_offsets_and_names: nil

    @type t :: %__MODULE__{
      prettify: Boolean,
      tag_offsets_and_names: map
    }
  end

  @doc """
  EXIF/TIFF data can be loaded from tiff binary files 
  """
  def parse_tiff_file(filepath, options \\ %ExifParser.Options{}) do
    with {:ok, buffer} <- File.open(filepath, [:read], &IO.binread(&1, @max_length)),
         {:ok, tiff} <- parse_tiff_binary(buffer, options) do
      {:ok, tiff}
    else
      err -> err
    end
  end

  @doc """
  EXIF/TIFF data can be loaded from tiff binary buffers
  """
  def parse_tiff_binary(
        <<header::binary-size(8), _rest::binary>> = start_of_tiff,
        options \\ %ExifParser.Options{}
      ) do
    with {:ok, header} <- Header.parse(header),
         tags <-
           IFD.parse_tiff_body(
             header.identifier,
             start_of_tiff,
             header.ifd_offset,
             options.prettify
           ),
         custom_tags <-
           CLT.parse_custom_tags(
             options.tag_offsets_and_names,
             header.identifier,
             start_of_tiff,
             options.prettify
           ) do
      case custom_tags do
        nil -> {:ok, tags}
        custom_tags -> {:ok, tags, custom_tags}
      end
    else
      err -> err
    end
  end

  @doc """
  EXIF/TIFF data can be loaded from jpeg binary files 
  """
  def parse_jpeg_file(filepath, options \\ %ExifParser.Options{}) do
    with {:ok, buffer} <- File.open(filepath, [:read], &IO.binread(&1, @max_length)),
         {:ok, buffer} <- find_app1(buffer),
         {:ok, tiff} <- parse_tiff_binary(buffer, options) do
      {:ok, tiff}
    else
      err -> err
    end
  end

  defp find_app1(<<@jpeg_app1::16, _length::16, "Exif"::binary, 0::16, rest::binary>>),
    do: {:ok, rest}

  defp find_app1(<<@jpeg_start_of_image::16, rest::binary>>), do: find_app1(rest)

  defp find_app1(<<0xFF::8, _num::8, len::16, rest::binary>>) do
    # Not app1, skip it
    # the len desciption is part of the length
    len = len - 2
    <<_skip::size(len)-unit(8), rest::binary>> = rest
    find_app1(rest)
  end

  defp find_app1(_), do: {:error, "Can't find app1 in jpeg image"}
end
