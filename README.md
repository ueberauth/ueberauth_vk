# Überauth VK
[![Build Status][travis-img]][travis] [![License][license-img]][license]

[travis-img]: https://travis-ci.org/sobolevn/ueberauth_vk.png?branch=master
[travis]: https://travis-ci.org/sobolevn/ueberauth_vk
[license-img]: http://img.shields.io/badge/license-MIT-brightgreen.svg
[license]: http://opensource.org/licenses/MIT

> VK OAuth2 strategy for Überauth.

## Installation

1. Setup your application at [VK Developers](https://vk.com/dev).

1. Add `:ueberauth_vk` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      # installation via hex:
      [{:ueberauth_vk, "~> 0.1.0"}]
      # if you want to use github:
      # [{:ueberauth_vk, github: "sobolevn/ueberauth_vk"}]
    end
    ```

1. Add the strategy to your applications:

    ```elixir
    def application do
      [applications: [:ueberauth_vk]]
    end
    ```

1. Add VK to your Überauth configuration:

    ```elixir
    config :ueberauth, Ueberauth,
      providers: [
        vk: {Ueberauth.Strategy.VK, []}
      ]
    ```

1.  Update your provider configuration:

    ```elixir
    config :ueberauth, Ueberauth.Strategy.VK.OAuth,
      client_id: System.get_env("VK_CLIENT_ID"),
      client_secret: System.get_env("VK_CLIENT_SECRET")
    ```

1.  Include the Überauth plug in your controller:

    ```elixir
    defmodule MyApp.AuthController do
      use MyApp.Web, :controller
      plug Ueberauth
      ...
    end
    ```

1.  Create the request and callback routes if you haven't already:

    ```elixir
    scope "/auth", MyApp do
      pipe_through :browser

      get "/:provider", AuthController, :request
      get "/:provider/callback", AuthController, :callback
    end
    ```

1. You controller needs to implement callbacks to deal with `Ueberauth.Auth` and `Ueberauth.Failure` responses.

For an example implementation see the [Überauth Example](https://github.com/ueberauth/ueberauth_example) application.

## Calling

Depending on the configured url you can initial the request through:

    /auth/vk

Or with options:

    /auth/vk?scope=friends,video,offline

By default the requested scope is "public_profile". Scope can be configured either explicitly as a `scope` query value on the request path or in your configuration:

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

Please see [LICENSE](https://github.com/ueberauth/ueberauth_vk/blob/master/LICENSE) for licensing details.
