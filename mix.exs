defmodule UeberauthVK.Mixfile do
  use Mix.Project

  @version "0.3.0"
  @url "https://github.com/sobolevn/ueberauth_vk"

  def project do
    [
      app: :ueberauth_vk,
      version: @version,
      name: "Ueberauth VK Strategy",
      package: package(),
      elixir: "~> 1.4",

      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,

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
        "coveralls": :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
      ],
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
   [
     # Auth:
     {:ueberauth, "~> 0.4"},
     {:oauth2, "~> 0.9"},

     # Tests:
     {:exvcr, "~> 0.10", only: :test},
     {:excoveralls, ">= 0.0.0", only: :test},

     # Docs:
     {:ex_doc, ">= 0.0.0", only: :dev},

     # Lint:
     {:credo, "~> 0.8", only: [:dev, :test]},
   ]
  end

  defp docs do
    # Docs
    [source_ref: "v#{@version}",
     main: "README",
     canonical: "http://hexdocs.pm/ueberauth_vk",
     source_url: @url,
     extras: ["README.md"]]
  end

  defp description do
    "An Uberauth strategy for VK authentication."
  end

  defp package do
    [files: ["lib", "mix.exs", "README.md", "LICENSE.md"],
     maintainers: ["Sobolev Nikita"],
     licenses: ["MIT"],
     links: %{"GitHub": @url}]
  end
end
