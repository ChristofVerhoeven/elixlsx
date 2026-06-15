defmodule Elixlsx.Mixfile do
  use Mix.Project

  @source_url "https://github.com/ChristofVerhoeven/elixlsx"
  @version "0.7.0"

  def project do
    [
      app: :elixlsx,
      version: @version,
      elixir: "~> 1.19",
      package: package(),
      description: "Elixlsx is a writer for the MS Excel OpenXML format (`.xlsx`).",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs()
    ]
  end

  def application do
    [extra_applications: [:xmerl]]
  end

  defp deps do
    [
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:propcheck, "~> 1.4", only: [:dev, :test]},
      {:ex_doc, "~> 0.40", only: [:dev], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false}
    ]
  end

  defp docs do
    [
      extras: ["CHANGELOG.md", "README.md"],
      main: "readme",
      source_url: @source_url,
      source_ref: "v#{@version}"
    ]
  end

  defp package do
    [
      maintainers: ["Christof Verhoeven"],
      licenses: ["MIT"],
      links: %{
        "Changelog" => "https://github.com/ChristofVerhoeven/elixlsx/blob/master/CHANGELOG.md",
        "GitHub" => @source_url
      }
    ]
  end
end
