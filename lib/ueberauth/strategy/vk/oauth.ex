defmodule Ueberauth.Strategy.VK.OAuth do
  @moduledoc ~S"""
  OAuth2 for VK.

  Add `client_id` and `client_secret` to your configuration:

      config :ueberauth, Ueberauth.Strategy.VK.OAuth,
        client_id: System.get_env("VK_APP_ID"),
        client_secret: System.get_env("VK_APP_SECRET")
  """
  use OAuth2.Strategy

  alias OAuth2.Client
  alias OAuth2.Strategy.AuthCode

  @defaults [
    strategy: __MODULE__,
    site: "https://api.vk.com/method",
    authorize_url: "https://oauth.vk.com/authorize",
    token_url: "https://oauth.vk.com/access_token"
  ]

  @doc """
  Construct a client for requests to vk.com

  This will be setup automatically for you in `Ueberauth.Strategy.VK`.
  These options are only useful for usage outside the normal callback phase
  of Ueberauth.
  """
  def client(opts \\ []) do
    config = Application.get_env(:ueberauth, Ueberauth.Strategy.VK.OAuth)

    opts =
      @defaults
      |> Keyword.merge(config)
      |> Keyword.merge(opts)

    Client.new(opts)
  end

  @doc """
  Provides the authorize url for the request phase of Ueberauth.
  No need to call this usually.
  """
  def authorize_url!(params \\ [], opts \\ []) do
    opts
    |> client()
    |> Client.authorize_url!(params)
  end

  def get_token!(params \\ [], opts \\ []) do
    opts
    |> client()
    |> put_param(:client_secret, client().client_secret)
    |> Client.get_token!(params)
  end

  # Strategy Callbacks

  def authorize_url(client, params) do
    AuthCode.authorize_url(client, params)
  end

  def get_token(client, params, headers) do
    client
    |> put_header("Accept", "application/json")
    |> AuthCode.get_token(params, headers)
  end
end
