defmodule UeberauthVK.Mixfile do
  use Mix.Project

  @version "0.5.0"
  @url "https://github.com/ueberauth/ueberauth_vk"

  def project do
    [
      app: :ueberauth_vk,
      version: @version,
      name: "Ueberauth VK Strategy",
      package: package(),
      elixir: "~> 1.11",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      source_url: @url,
      homepage_url: @url,
      description: description(),
      deps: deps(),

      # Docs
      name: "ueberauth_vk",
      docs: docs(),

      # Test coverage:
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      # Auth:
      {:ueberauth, "~> 0.10"},
      {:oauth2, "~> 1.0 or ~> 2.0"},

      # Tests:
      {:mock, "~> 0.3", only: :test},
      {:excoveralls, ">= 0.0.0", only: :test},

      # Docs:
      {:ex_doc, ">= 0.29.0", only: :dev, runtime: false},

      # Lint:
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false}
    ]
  end

  defp docs do
    [extras: ["README.md"], main: "readme"]
  end

  defp description do
    "An Uberauth strategy for VK authentication."
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE.md"],
      maintainers: ["Sobolev Nikita"],
      licenses: ["MIT"],
      links: %{GitHub: @url}
    ]
  end
end
