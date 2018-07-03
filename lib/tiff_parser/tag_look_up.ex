defmodule TiffParser.TagLookUp do
  alias TiffParser.Tag
  
  def look_up_name(%Tag{tag_id: 0x00fe} = tag), do: %Tag{tag | tag_id: :sub_file_type}
  def look_up_name(%Tag{tag_id: 0x0100} = tag), do: %Tag{tag | tag_id: :image_width}
  def look_up_name(%Tag{tag_id: 0x0101} = tag), do: %Tag{tag | tag_id: :image_height}
  def look_up_name(%Tag{tag_id: 0x0102} = tag), do: %Tag{tag | tag_id: :bits_per_sample}
  def look_up_name(%Tag{tag_id: 0x0103} = tag), do: %Tag{tag | tag_id: :compression}
  def look_up_name(%Tag{tag_id: 0x0106} = tag), do: %Tag{tag | tag_id: :photometric_interpretation}
  def look_up_name(%Tag{tag_id: 0x0111} = tag), do: %Tag{tag | tag_id: :strip_offsets}
  def look_up_name(%Tag{tag_id: 0x0115} = tag), do: %Tag{tag | tag_id: :samples_per_pixel}
  def look_up_name(%Tag{tag_id: 0x0116} = tag), do: %Tag{tag | tag_id: :rows_per_strip}
  def look_up_name(%Tag{tag_id: 0x0117} = tag), do: %Tag{tag | tag_id: :strip_byte_counts}
  def look_up_name(%Tag{tag_id: 0x011c} = tag), do: %Tag{tag | tag_id: :planar_configuration}
  def look_up_name(%Tag{tag_id: 0x0132} = tag), do: %Tag{tag | tag_id: :data_time}
  def look_up_name(%Tag{tag_id: 0x8769} = tag), do: %Tag{tag | tag_id: :exif}
  def look_up_name(%Tag{tag_id: 0x9216} = tag), do: %Tag{tag | tag_id: :tiff_ep_standard}
  
  def look_up_name(tag), 
    do: tag
end
