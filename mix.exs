defmodule Commander.MixProject do
  use Mix.Project

  @version "1.2.1"

  def project do
    [
      app: :commander,
      version: @version,
      description: description(),
      package: package(),
      aliases: aliases(),
      elixir: "~> 1.9",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "Commander",
      source_url: "https://github.com/bettorplace/commander"
    ]
  end

  defp description do
    """
    Library used to execute commands in a structured way
    """
  end

  defp package do
    [
      files: [
        "lib",
        "mix.exs",
        ".formatter.exs",
        "README*",
        "LICENSE*",
        "test/commander",
        "test/support"
      ],
      maintainers: ["David Jeusette"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/bettorplace/commander"
      }
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(:dev), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    [
      extra_applications: [:logger],
      mod: {Commander.Application, []}
    ]
  end

  defp aliases do
    []
  end

  defp deps do
    [
      {:elixir_uuid, "~> 1.2"},
      {:ecto, ">= 3.1.7"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end
end
