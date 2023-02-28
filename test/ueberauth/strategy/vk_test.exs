defmodule Ueberauth.Strategy.VKTest do
  use ExUnit.Case, async: false
  use Plug.Test

  import Mock
  import Plug.Conn
  import Ueberauth.Strategy.Helpers

  setup_with_mocks([
    {OAuth2.Client, [:passthrough],
      [
        get_token: &oauth2_get_token/2,
        get: &oauth2_get/4
      ]}
  ]) do
    # Create a connection with Ueberauth's CSRF cookies so they can be recycled during tests
    routes = Ueberauth.init([])
    csrf_conn = conn(:get, "/auth/vk", %{}) |> Ueberauth.call(routes)
    csrf_state = with_state_param([], csrf_conn) |> Keyword.get(:state)

    {:ok, csrf_conn: csrf_conn, csrf_state: csrf_state}
  end

  def set_options(routes, conn, opt) do
    case Enum.find_index(routes, &(elem(&1, 0) == {conn.request_path, conn.method})) do
      nil ->
        routes
      idx ->
        update_in(routes, [Access.at(idx), Access.elem(1), Access.elem(2)], &%{&1 | options: opt})
    end
  end

  defp token(client, opts) do
    {:ok, %{client | token: OAuth2.AccessToken.new(%{"access_token" => opts, "email" => "durov@vk.com"})}}
  end
  defp response(body, code \\ 200) do
    {:ok, %OAuth2.Response{status_code: code, body: %{"response" => body}}}
  end

  def oauth2_get_token(client, code: "success_code"), do: token(client, "success_token")
  def oauth2_get_token(_client, code: "oauth2_error"), do: {:error, %OAuth2.Error{reason: :timeout}}

  def oauth2_get_token(_client, code: "error_response"),
    do: {:error, %OAuth2.Response{body: %{"error" => "some error", "error_description" => "something went wrong"}}}

  def oauth2_get(%{token: %{access_token: "success_token"}}, url, _, _) do
    basic_user_response = %{"id" => 1, "first_name" => "Pavel", "last_name" => "Durov"}
    uri = URI.parse(url)
    query_params = URI.decode_query(uri.query)

    # Add response for a requested optional fields
    user_response = if query_params["fields"] && query_params["fields"] != "" do
      fields = String.split(query_params["fields"], ",") |> Enum.map(&String.trim/1)
      Enum.reduce(fields, basic_user_response, fn(field_name, response) ->
        Map.put(response, field_name, "value_for_field_#{field_name}")
      end)
    else
      basic_user_response
    end

    response([user_response])
  end

  defp set_csrf_cookies(conn, csrf_conn) do
    conn
    |> init_test_session(%{})
    |> recycle_cookies(csrf_conn)
    |> fetch_cookies()
  end

  test "handle_request! redirects to appropriate auth uri" do
    conn = conn(:get, "/auth/vk", %{})
    # Make sure the hd and scope params are included for good measure
    routes = Ueberauth.init() |> set_options(conn, hd: "example.com", default_scope: "email photos")

    resp = Ueberauth.call(conn, routes)

    assert resp.status == 302
    assert [location] = get_resp_header(resp, "location")

    redirect_uri = URI.parse(location)
    assert redirect_uri.host == "oauth.vk.com"
    assert redirect_uri.path == "/authorize"

    assert %{
              "client_id" => "appid",
              "redirect_uri" => "http://www.example.com/auth/vk/callback",
              "response_type" => "code",
              "scope" => "email photos"
            } = Plug.Conn.Query.decode(redirect_uri.query)
  end

  test "handle_callback! assigns required fields on successful auth", %{csrf_state: csrf_state, csrf_conn: csrf_conn} do
    conn = conn(:get, "/auth/vk/callback", %{code: "success_code", state: csrf_state}) |> set_csrf_cookies(csrf_conn)

    routes = Ueberauth.init()
    assert %Plug.Conn{assigns: %{ueberauth_auth: auth}} = Ueberauth.call(conn, routes)
    assert auth.provider == :vk
    assert auth.strategy == Ueberauth.Strategy.VK
    assert auth.credentials.token == "success_token"
    assert auth.info.name == "Pavel Durov"
    assert auth.info.email == "durov@vk.com"
    assert auth.info.urls == %{vk: "https://vk.com/id1"}
    assert auth.info.image == nil
    assert auth.info.nickname == nil
    assert auth.uid == 1
  end

  test "handle_callback! assigns extra fields on successful auth", %{csrf_state: csrf_state, csrf_conn: csrf_conn} do
    conn = conn(:get, "/auth/vk/callback", %{code: "success_code", state: csrf_state}) |> set_csrf_cookies(csrf_conn)

    routes = Ueberauth.init() |> set_options(conn, profile_fields: "photo_200, domain")
    assert %Plug.Conn{assigns: %{ueberauth_auth: auth}} = Ueberauth.call(conn, routes)
    assert auth.provider == :vk
    assert auth.strategy == Ueberauth.Strategy.VK
    assert auth.credentials.token == "success_token"
    assert auth.info.name == "Pavel Durov"
    assert auth.info.email == "durov@vk.com"
    assert auth.info.urls == %{vk: "https://vk.com/id1"}
    assert auth.info.image == "value_for_field_photo_200"
    assert auth.info.nickname == "value_for_field_domain"
    assert auth.uid == 1
  end

  test "state param is present in the redirect uri" do
    conn = conn(:get, "/auth/vk", %{})

    routes = Ueberauth.init()
    resp = Ueberauth.call(conn, routes)

    assert [location] = get_resp_header(resp, "location")

    redirect_uri = URI.parse(location)
    assert redirect_uri.query =~ "state="
  end

  describe "error handling" do
    test "handle_callback! handles Oauth2.Error", %{csrf_state: csrf_state, csrf_conn: csrf_conn} do
      conn = conn(:get, "/auth/vk/callback", %{code: "oauth2_error", state: csrf_state}) |> set_csrf_cookies(csrf_conn)

      routes = Ueberauth.init([])
      assert %Plug.Conn{assigns: %{ueberauth_failure: failure}} = Ueberauth.call(conn, routes)
      assert %Ueberauth.Failure{errors: [%Ueberauth.Failure.Error{message: "timeout", message_key: "error"}]} = failure
    end

    test "handle_callback! handles error response", %{csrf_state: csrf_state, csrf_conn: csrf_conn} do
      conn = conn(:get, "/auth/vk/callback", %{code: "error_response", state: csrf_state}) |> set_csrf_cookies(csrf_conn)

      routes = Ueberauth.init([])
      assert %Plug.Conn{assigns: %{ueberauth_failure: failure}} = Ueberauth.call(conn, routes)
      assert %Ueberauth.Failure{
                errors: [%Ueberauth.Failure.Error{message: "something went wrong", message_key: "some error"}]
              } = failure
    end
  end
end
