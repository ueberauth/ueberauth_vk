defmodule Ueberauth.Strategy.VK do
  @moduledoc """
  VK Strategy for Überauth.
  """

  use Ueberauth.Strategy, default_scope: "",
                          default_display: "page",
                          profile_fields: "",
                          uid_field: :uid,
                          allowed_request_params: [
                            :display,
                            :scope
                          ]


  alias Ueberauth.Auth.Info
  alias Ueberauth.Auth.Credentials
  alias Ueberauth.Auth.Extra

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
      |> Enum.filter(fn {k, _} -> Enum.member?(allowed_params, k) end)
      |> Enum.map(fn {k, v} -> {String.to_existing_atom(k), v} end)
      |> Keyword.put(:redirect_uri, callback_url(conn))
      |> Ueberauth.Strategy.VK.OAuth.authorize_url!

    redirect!(conn, authorize_url)
  end

  @doc """
  Handles the callback from VK.
  """
  def handle_callback!(%Plug.Conn{params: %{"code" => code}} = conn) do
    opts = [redirect_uri: callback_url(conn)]
    token = Ueberauth.Strategy.VK.OAuth.get_token!([code: code], opts)

    if token.access_token == nil do
      err = token.other_params["error"]
      desc = token.other_params["error_description"]
      set_errors!(conn, [error(err, desc)])
    else
      fetch_user(conn, token)
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
    scopes = token.other_params["scope"] || ""
    scopes = String.split(scopes, ",")

    %Credentials{
      expires: !!token.expires_at,
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
        vk: "https://vk.com/" <> to_string(user["uid"])
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

  defp fetch_name(user), do: user["first_name"] <> " " <> user["last_name"]

  defp fetch_image(user) do
    user_photo =
      user
      |> Enum.filter(fn {k, _v} -> String.starts_with?(k, "photo_") end)
      |> Enum.sort_by(fn {"photo_" <> size, _v} -> Integer.parse(size) end)
      |> List.last

    case user_photo do
      nil -> nil
      {_, photo_url} -> photo_url
    end
  end

  defp fetch_user(conn, token) do
    conn = put_private(conn, :vk_token, token)
    path = user_query(conn)

    case OAuth2.AccessToken.get(token, path) do
      {:ok, %OAuth2.Response{status_code: 401, body: _body}} ->
        set_errors!(conn, [error("token", "unauthorized")])
      {:ok, %OAuth2.Response{status_code: status_code, body: user}}
        when status_code in 200..399 ->
        put_private(conn, :vk_user, List.first(user["response"]))
      {:error, %OAuth2.Error{reason: reason}} ->
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
      |> URI.encode_query
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

  defp option(conn, key) do
    default = Keyword.get(default_options, key)

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
      Map.put(params, name,option(params[name], conn, config_key))
    end
  end
end
