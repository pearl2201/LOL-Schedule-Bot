defmodule FacebookBot.Repo do
  use Ecto.Repo,
    otp_app: :facebook_bot,
    adapter: Ecto.Adapters.Postgres
end
