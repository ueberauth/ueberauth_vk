defmodule SpecRouter do
  # Credit goes to:
  # https://github.com/he9qi/ueberauth_weibo/blob/master/test/test_helper.exs

  require Ueberauth
  use Plug.Router

  plug(:fetch_query_params)

  plug(Ueberauth, base_path: "/auth")

  plug(:match)
  plug(:dispatch)

  get("/auth/vk", do: send_resp(conn, 200, "vk request"))

  get("/auth/vk/callback", do: send_resp(conn, 200, "vk callback"))
end

ExUnit.start()
