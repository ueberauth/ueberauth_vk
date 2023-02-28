import Config

config :ueberauth, Ueberauth,
  providers: [
    vk: {Ueberauth.Strategy.VK, []}
  ]

config :ueberauth, Ueberauth.Strategy.VK.OAuth,
  client_id: "appid",
  client_secret: "secret",
  redirect_uri: "/callback"

config :plug, :validate_header_keys_during_test, true
