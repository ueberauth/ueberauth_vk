defmodule Ueberauth.Strategy.VK do
  @moduledoc """
  VK Strategy for Überauth.

  ### Setup

  Create an VK application for you to use.

  Register a new application at: [VK devs](https://vk.com/dev) and get the `client_id` and `client_secret`.

  Include the provider in your configuration for Ueberauth

      config :ueberauth, Ueberauth,
        providers: [
          vk: { Ueberauth.Strategy.VK, [] }
        ]

  Then include the configuration for github.

      config :ueberauth, Ueberauth.Strategy.VK.OAuth,
        client_id: System.get_env("VK_CLIENT_ID"),
        client_secret: System.get_env("VK_CLIENT_SECRET"),

  If you haven't already, create a pipeline and setup routes for your callback handler

      pipeline :auth do
        Ueberauth.plug "/auth"
      end
      scope "/auth" do
        pipe_through [:browser, :auth]
        get "/:provider/callback", AuthController, :callback
      end

  Create an endpoint for the callback where you will handle the `Ueberauth.Auth` struct

      defmodule MyApp.AuthController do
        use MyApp.Web, :controller

        def callback_phase(%{ assigns: %{ ueberauth_failure: fails } } = conn, _params) do
          # do things with the failure
        end
        def callback_phase(%{ assigns: %{ ueberauth_auth: auth } } = conn, params) do
          # do things with the auth
        end
      end

  You can edit the behaviour of the Strategy by including some options when you register your provider.

  You can customize [multiple fields](https://vk.com/dev/auth_sites), such as `default_scope`, `default_display`, `default_state`, `profile_fields`, `uid_field`

      config :ueberauth, Ueberauth,
        providers: [
          vk: { Ueberauth.Strategy.VK, [
            default_scope: "email,friends,video,offline",
            default_display: "popup",
            default_state: "secret-state-value",
            uid_field: :email
          ] }
        ]

  Default is empty ("") which "Grants read-only access to public information (includes public user profile info, public repository info, and gists)"

  """

  use Ueberauth.Strategy,
    default_scope: "",
    default_display: "page",
    default_state: "",
    profile_fields: "",
    uid_field: :uid,
    allowed_request_params: [
      :display,
      :scope,
      :state
    ]

  alias OAuth2.{Response, Error, Client}
  alias Ueberauth.Auth.{Info, Credentials, Extra}
  alias Ueberauth.Strategy.VK.OAuth

  @doc """
  Handles initial request for VK authentication.
  """
  def handle_request!(conn) do
    allowed_params =
      conn
      |> option(:allowed_request_params)
      |> Enum.map(&to_string/1)

    authorize_url =
      conn.params
      |> maybe_replace_param(conn, "auth_type", :auth_type)
      |> maybe_replace_param(conn, "scope", :default_scope)
      |> maybe_replace_param(conn, "display", :default_display)
      |> maybe_replace_param(conn, "state", :default_state)
      |> Enum.filter(fn {k, _} -> Enum.member?(allowed_params, k) end)
      |> Enum.map(fn {k, v} -> {String.to_existing_atom(k), v} end)
      |> Keyword.put(:redirect_uri, callback_url(conn))
      |> OAuth.authorize_url!()

    redirect!(conn, authorize_url)
  end

  @doc """
  Handles the callback from VK.
  """
  def handle_callback!(%Plug.Conn{params: %{"code" => _}} = conn) do
    {code, state} = parse_params(conn)
    opts = [redirect_uri: callback_url(conn)]
    client = OAuth.get_token!([code: code], opts)
    token = client.token

    if token.access_token == nil do
      err = token.other_params["error"]
      desc = token.other_params["error_description"]
      set_errors!(conn, [error(err, desc)])
    else
      fetch_user(conn, client, state)
    end
  end

  @doc false
  def handle_callback!(conn) do
    set_errors!(conn, [error("missing_code", "No code received")])
  end

  @doc false
  def handle_cleanup!(conn) do
    conn
    |> put_private(:vk_user, nil)
    |> put_private(:vk_token, nil)
  end

  @doc """
  Fetches the uid field from the response.
  """
  def uid(conn) do
    uid_field =
      conn
      |> option(:uid_field)
      |> to_string

    conn.private.vk_user[uid_field]
  end

  @doc """
  Includes the credentials from the VK response.
  """
  def credentials(conn) do
    token = conn.private.vk_token

    scopes =
      String.split(
        token.other_params["scope"] || "",
        ","
      )

    %Credentials{
      expires: token.expires_at == nil,
      expires_at: token.expires_at,
      scopes: scopes,
      token: token.access_token
    }
  end

  @doc """
  Fetches the fields to populate the info section of the
  `Ueberauth.Auth` struct.
  """
  def info(conn) do
    token = conn.private.vk_token
    user = conn.private.vk_user

    %Info{
      first_name: user["first_name"],
      last_name: user["last_name"],
      email: token.other_params["email"],
      name: fetch_name(user),
      image: fetch_image(user),
      location: user["city"],
      description: user["about"],
      urls: %{
        vk: "https://vk.com/id" <> to_string(user["uid"])
      }
    }
  end

  @doc """
  Stores the raw information (including the token) obtained from
  the vk callback.
  """
  def extra(conn) do
    %Extra{
      raw_info: %{
        token: conn.private.vk_token,
        user: conn.private.vk_user
      }
    }
  end

  defp parse_params(%Plug.Conn{params: %{"code" => code, "state" => state}}) do
    {code, state}
  end

  defp parse_params(%Plug.Conn{params: %{"code" => code}}) do
    {code, nil}
  end

  defp fetch_name(user), do: user["first_name"] <> " " <> user["last_name"]

  defp fetch_image(user) do
    user_photo =
      user
      |> Enum.filter(fn {k, _v} -> String.starts_with?(k, "photo_") end)
      |> Enum.sort_by(fn {"photo_" <> size, _v} -> Integer.parse(size) end)
      |> List.last()

    case user_photo do
      nil -> nil
      {_, photo_url} -> photo_url
    end
  end

  defp fetch_user(conn, client, state) do
    conn =
      conn
      |> put_private(:vk_token, client.token)
      |> put_private(:vk_state, state)

    path = user_query(conn)

    case Client.get(client, path) do
      {:ok, %Response{status_code: 401, body: _body}} ->
        set_errors!(conn, [error("token", "unauthorized")])

      {:ok, %Response{status_code: status_code, body: user}}
      when status_code in 200..399 ->
        put_private(conn, :vk_user, List.first(user["response"]))

      {:error, %Error{reason: reason}} ->
        set_errors!(conn, [error("OAuth2", reason)])
    end
  end

  defp user_query(conn) do
    query =
      conn
      |> query_params(:locale)
      |> Map.merge(query_params(conn, :profile))
      |> Map.merge(query_params(conn, :user_id))
      |> Map.merge(query_params(conn, :access_token))
      |> Map.merge(query_params(conn, :version))
      |> URI.encode_query()

    "https://api.vk.com/method/users.get?#{query}"
  end

  defp query_params(conn, :profile) do
    case option(conn, :profile_fields) do
      nil -> %{}
      fields -> %{"fields" => fields}
    end
  end

  defp query_params(conn, :locale) do
    case option(conn, :locale) do
      nil -> %{}
      locale -> %{"lang" => locale}
    end
  end

  defp query_params(conn, :user_id) do
    %{"user_ids" => conn.private.vk_token.other_params["user_id"]}
  end

  defp query_params(conn, :access_token) do
    %{"access_token" => conn.private.vk_token.access_token}
  end

  defp query_params(_conn, :version) do
    %{"v" => "5.124"}
  end

  defp option(conn, key) do
    default = Keyword.get(default_options(), key)

    conn
    |> options
    |> Keyword.get(key, default)
  end

  defp option(nil, conn, key), do: option(conn, key)
  defp option(value, _conn, _key), do: value

  defp maybe_replace_param(params, conn, name, config_key) do
    if params[name] do
      params
    else
      Map.put(params, name, option(params[name], conn, config_key))
    end
  end
end
