defmodule Ueberauth.Strategy.VKTest do
  # Test resources:
  use ExUnit.Case, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  use Plug.Test

  # Custom data:
  import Ueberauth.Strategy.VK, only: [info: 1]
  alias Ueberauth.Auth.Info

  # Initializing utils:
  doctest Ueberauth.Strategy.VK

  @router SpecRouter.init([])
  @test_email "test@mail.ru"

  # Setups:
  setup_all do
    # Creating token:
    token = %{other_params: %{"email" => @test_email}}

    # Read the fixture with the user information:
    {:ok, json} =
      "test/fixtures/vk.json"
      |> Path.expand()
      |> File.read()

    user_info = Poison.decode!(json)

    {:ok, response} =
      "test/fixtures/vk_response.html"
      |> Path.expand()
      |> File.read()

    response = String.replace(response, "\n", "")

    {:ok,
     %{
       user_info: user_info,
       token: token,
       response: response
     }}
  end

  # Tests:

  test "request phase", fixtures do
    conn =
      :get
      |> conn("/auth/vk")
      |> SpecRouter.call(@router)

    assert conn.resp_body == fixtures.response
  end

  test "default callback phase" do
    query = %{code: "code_abc"} |> URI.encode_query()

    use_cassette "httpoison_get" do
      conn =
        :get
        |> conn("/auth/vk/callback?#{query}")
        |> SpecRouter.call(@router)

      assert conn.resp_body == "vk callback"

      auth = conn.assigns.ueberauth_auth

      assert auth.provider == :vk
      assert auth.strategy == Ueberauth.Strategy.VK
      assert auth.uid == 210_700_286
    end
  end

  test "callback phase with state" do
    query = %{code: "code_abc", state: "abc"} |> URI.encode_query()

    use_cassette "httpoison_get" do
      conn =
        :get
        |> conn("/auth/vk/callback?#{query}")
        |> SpecRouter.call(@router)

      assert conn.resp_body == "vk callback"

      auth = conn.assigns.ueberauth_auth

      assert auth.provider == :vk
      assert auth.strategy == Ueberauth.Strategy.VK
      assert auth.uid == 210_700_286
    end
  end

  test "user information parsing", fixtures do
    user_info = fixtures.user_info
    token = fixtures.token

    conn = %Plug.Conn{
      private: %{
        vk_user: user_info,
        vk_token: token
      }
    }

    assert info(conn) == %Info{
             email: @test_email,
             name: "Lindsey Stirling",
             first_name: "Lindsey",
             last_name: "Stirling",
             nickname: nil,
             location: 5331,
             description: "some info",
             image: "100.jpg",
             urls: %{
               vk: "https://vk.com/id210700286"
             }
           }
  end
end
