defmodule ExDhcp.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_dhcp,
      version: "0.1.5",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      description: description(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [coveralls: :test, "coveralls.detail": :test, "coveralls.post": :test, "coveralls.html": :test],
      source_url: "https://github.com/ityonemo/ex_dhcp",
      package: package(),
      docs: docs()
    ]
  end

  defp description do
    "A library to help implementing servers which need to issue DHCP requests"
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/ityonemo/ex_dhcp"}
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:elixir_uuid, "~> 1.2", only: [:test]},
      {:credo, "~> 1.7", only: [:test, :dev], runtime: false},
      {:dialyxir, "~> 1.4.5", only: :dev, runtime: false},
      {:licensir, "~> 0.7", only: :dev, runtime: false},
      {:ex_doc, "~> 0.34.2", only: :dev, runtime: false},
      {:excoveralls, "~> 0.18.3", only: :test}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp docs() do
    [
      main: "ExDhcp",
      extra_section: "GUIDES",
      extras: [
        "README.md",
        "pxe_guide.md"],
      groups_for_extras: ["Guides": "pxe_guide.md"]
    ]
  end
end
