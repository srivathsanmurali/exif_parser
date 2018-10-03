defmodule ExifParser.MixProject do
  use Mix.Project

  def project do
    [
      app: :exif_parser,
      version: "0.2.3",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      description: description(),
      name: "exif_parser",
      source_url: "https://github.com/srivathsanmurali/exif_parser"
    ]
  end

  def application do
    []
  end

  defp deps do
    [
      {:ex_doc, "~> 0.16", only: :dev, runtime: false}
    ]
  end

  defp description() do
    "Parse EXIF/TIFF metadata from JPEG and TIFF files."
  end

  defp package() do
    [
      name: "exif_parser",
      maintainers: ["Srivathsan Murali"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/srivathsanmurali/exif_parser"}
    ]
  end
end
