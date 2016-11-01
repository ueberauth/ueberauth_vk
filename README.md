# Überauth VK

[![Build Status][travis-img]][travis] [![Coverage Status][coverage-img]][coverage] [![Hex Version][hex-img]][hex] [![License][license-img]][license]

> VK OAuth2 strategy for Überauth.

## Requirements

We support `elixir` versions `1.2` and bellow.

## Installation

1. Setup your application at [VK Developers](https://vk.com/dev).

2. Add `:ueberauth_vk` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      # installation via hex:
      [{:ueberauth_vk, "~> 0.2"}]
      # if you want to use github:
      # [{:ueberauth_vk, github: "sobolevn/ueberauth_vk"}]
    end
    ```

3. Add the strategy to your applications:

    ```elixir
    def application do
      [applications: [:ueberauth_vk]]
    end
    ```

4. Add VK to your Überauth configuration:

    ```elixir
    config :ueberauth, Ueberauth,
      providers: [
        vk: {Ueberauth.Strategy.VK, []}
      ]
    ```

5.  Update your provider configuration:

    ```elixir
    config :ueberauth, Ueberauth.Strategy.VK.OAuth,
      client_id: System.get_env("VK_CLIENT_ID"),
      client_secret: System.get_env("VK_CLIENT_SECRET")
    ```

6.  Include the Überauth plug in your controller:

    ```elixir
    defmodule MyApp.AuthController do
      use MyApp.Web, :controller
      plug Ueberauth
      ...
    end
    ```

7.  Create the request and callback routes if you haven't already:

    ```elixir
    scope "/auth", MyApp do
      pipe_through :browser

      get "/:provider", AuthController, :request
      get "/:provider/callback", AuthController, :callback
    end
    ```

8. You controller needs to implement callbacks to deal with `Ueberauth.Auth` and `Ueberauth.Failure` responses.

For an example implementation see the [Überauth Example](https://github.com/ueberauth/ueberauth_example) application.

## Calling

Depending on the configured url you can initial the request through: `/auth/vk`

Or with options: `/auth/vk?scope=friends,video,offline`

By default the requested scope is `"public_profile"`. Scope can be configured either explicitly as a `scope` query value on the request path or in your configuration:

```elixir
config :ueberauth, Ueberauth,
  providers: [
    vk: {Ueberauth.Strategy.VK, [default_scope: "friends,video,offline"]}
  ]
```

You can also provide custom fields for user profile:

```elixir
config :ueberauth, Ueberauth,
  providers: [
    vk: {Ueberauth.Strategy.VK, [profile_fields: "photo_200,location,online"]}
  ]
```

See [VK API Method Reference > User](https://vk.com/dev/users.get) for full list of fields.


## License

MIT. Please see [LICENSE.md](https://github.com/sobolevn/ueberauth_vk/blob/master/LICENSE.md) for licensing details.

  [travis-img]: https://img.shields.io/travis/sobolevn/ueberauth_vk/master.svg
  [travis]: https://travis-ci.org/sobolevn/ueberauth_vk
  [coverage-img]: https://coveralls.io/repos/github/sobolevn/ueberauth_vk/badge.svg?branch=master
  [coverage]: https://coveralls.io/github/sobolevn/ueberauth_vk?branch=master
  [hex-img]: https://img.shields.io/hexpm/v/ueberauth_vk.svg
  [hex]: https://hex.pm/packages/ueberauth_vk
  [license-img]: http://img.shields.io/badge/license-MIT-brightgreen.svg
  [license]: http://opensource.org/licenses/MIT
