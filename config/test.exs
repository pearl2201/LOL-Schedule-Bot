use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :facebook_bot, FacebookBotWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :facebook_bot, FacebookBot.Repo,
  username: "postgres",
  password: "postgres",
  database: "facebook_bot_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
