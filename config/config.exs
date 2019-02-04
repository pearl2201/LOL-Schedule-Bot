# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :facebook_bot,
  ecto_repos: [FacebookBot.Repo],
  page_access_token: System.get_env("PAGE_ACCESS_TOKEN"),
  x_api_key: System.get_env("X_API_KEY"),
  fb_app_secret: System.get_env("FB_APP_SECRET"),
  fb_app_verify_token: System.get_env("FB_APP_VERIFY_TOKEN")

# Configures the endpoint
config :facebook_bot, FacebookBotWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "Ri3up1pTuFDpgCbAR7mJxu812BSfV5o7u3666uwx0JUmBxmsU6y3jBR7nUOPHtGh",
  render_errors: [view: FacebookBotWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: FacebookBot.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"

config :facebook_bot, FacebookBot.Scheduler,
  jobs: [
    # Every 30 minute

    phoenix_job: [
      schedule: "*/30 * * * *",
      task: {FacebookBot.Task, :fetch_data, []}
    ]
  ]
