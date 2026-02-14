defmodule SimplexNoise.MixProject do
  use Mix.Project

  def project do
    [
      app: :simplex_noise,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "A fast simplex noise implementation in Elixir (2D, 3D, 4D)",
      package: package(),
      source_url: "https://github.com/bawolf/simplex_noise",
      docs: [main: "SimplexNoise"]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.35", only: :dev, runtime: false},
      {:benchee, "~> 1.0", only: :dev},
      {:benchee_markdown, "~> 0.3", only: :dev},
      {:stream_data, "~> 1.2", only: :test},
      {:jason, "~> 1.2", only: :test}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/bawolf/simplex_noise"
      }
    ]
  end
end
