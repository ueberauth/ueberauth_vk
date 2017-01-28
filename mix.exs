defmodule UeberauthVK.Mixfile do
  use Mix.Project

  @version "0.2.0"
  @url "https://github.com/sobolevn/ueberauth_vk"

  def project do
    [
      app: :ueberauth_vk,
      version: @version,
      name: "Ueberauth VK Strategy",
      package: package(),
      elixir: "~> 1.2",

      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,

      source_url: @url,
      homepage_url: @url,
      description: description(),
      deps: deps(),
      docs: docs(),

      # Test coverage:
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        "coveralls": :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
      ],
    ]
  end

  def application do
    [applications: [:logger, :oauth2, :ueberauth]]
  end

  defp deps do
   [
     # Auth:
     {:ueberauth, "~> 0.2"},
     {:oauth2, "~> 0.8.0"},

     # Tests:
     {:exvcr, "~> 0.8.4", only: :test},
     {:excoveralls, "~> 0.5", only: :test},

     # Docs:
     {:ex_doc, "~> 0.1", only: :dev},
     {:earmark, ">= 0.0.0", only: :dev},

     # Lint:
     {:dogma, "~> 0.1", only: [:dev, :test]},
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
      links: %{"GitHub": @url},
    ]
  end
end
