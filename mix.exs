defmodule ExDhcp.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_dhcp,
      version: "0.1.3",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      description: description(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [coveralls: :test, "coveralls.detail": :test, "coveralls.post": :test, "coveralls.html": :test],
      source_url: "https://github.com/RstorLabs/ex_dhcp",
      package: package(),
      docs: [main: "ExDhcp", extras: ["README.md"]]
    ]
  end

  defp description do
    "A library to help implementing servers which need to issue DHCP requests"
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/RstorLabs/ex_dhcp"}
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
      {:credo, "~> 1.1", only: [:test, :dev], runtime: false},
      {:dialyxir, "~> 0.5.1", only: :dev, runtime: false},
      {:licensir, "~> 0.4.2", only: :dev, runtime: false},
      {:ex_doc, "~> 0.20.2", only: :dev, runtime: false},
      {:excoveralls, "~> 0.11.1", only: :test}
    ]
  end
end
