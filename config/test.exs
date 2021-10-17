use Mix.Config

config :ueberauth, Ueberauth,
  providers: [
    vk: {Ueberauth.Strategy.VK, []}
  ]

config :ueberauth, Ueberauth.Strategy.VK.OAuth,
  client_id: "appid",
  client_secret: "secret",
  redirect_uri: "/callback"

config :exvcr,
  vcr_cassette_library_dir: "test/fixtures/vcr_cassettes"

config :plug, :validate_header_keys_during_test, true
