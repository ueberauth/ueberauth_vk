# Überauth VK

[![Build Status](https://img.shields.io/travis/sobolevn/ueberauth_vk/master.svg)](https://travis-ci.org/sobolevn/ueberauth_vk) [![Coverage Status](https://coveralls.io/repos/github/sobolevn/ueberauth_vk/badge.svg?branch=master)](https://coveralls.io/github/sobolevn/ueberauth_vk?branch=master) [![Hex Version](https://img.shields.io/hexpm/v/ueberauth_vk.svg)](https://hex.pm/packages/ueberauth_vk) [![License](http://img.shields.io/badge/license-MIT-brightgreen.svg)](http://opensource.org/licenses/MIT)

> VK OAuth2 strategy for Überauth.

## Requirements

We support `elixir` versions `1.4` and above.

## Installation

1. Setup your application at [VK Developers](https://vk.com/dev).

2. Add `:ueberauth_vk` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      # installation via hex:
      [{:ueberauth_vk, "~> 0.3"}]
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

## Customizing

You can customize [multiple fields](https://vk.com/dev/auth_sites), such as `default_scope`, `default_display`, `default_state`, `profile_fields`, and `uid_field`.

### Scope

By default the requested scope is `"public_profile"`. Scope can be configured either explicitly as a `scope` query value on the request path or in your configuration:

```elixir
config :ueberauth, Ueberauth,
  providers: [
    vk: {Ueberauth.Strategy.VK, [default_scope: "friends,video,offline"]}
  ]
```

### Profile Fields

You can also provide custom fields for user profile:

```elixir
config :ueberauth, Ueberauth,
  providers: [
    vk: {Ueberauth.Strategy.VK, [profile_fields: "photo_200,location,online"]}
  ]
```

See [VK API Method Reference > User](https://vk.com/dev/users.get) for full list of fields.

### State

You can also set the custom field called [`state`](https://github.com/sobolevn/ueberauth_vk/pull/20). It is used to prevent "man in the middle" attacks.

```elixir
config :ueberauth, Ueberauth,
  providers: [
    vk: {Ueberauth.Strategy.VK, [default_state: "secret-state-value"]}
  ]
```

This state will be passed to you in the callback as `/auth/vk?state=<session_id>` and will be available in the success struct.

### UID Field

You can use alternate fields to identify users. For example, you can use `email`.

```elixir
config :ueberauth, Ueberauth,
  providers: [
    vk: {Ueberauth.Strategy.VK, [
      default_scope: "email",
      uid_field: :email
    ]}
  ]
```


## License

MIT. Please see [LICENSE.md](https://github.com/sobolevn/ueberauth_vk/blob/master/LICENSE.md) for licensing details.
