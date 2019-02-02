defmodule FacebookBot.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec
    # List all child processes to be supervised
    children = [
      # Start the Ecto repository
      FacebookBot.Repo,
      # Start the endpoint when the application starts
      FacebookBotWeb.Endpoint,
      # Starts a worker by calling: FacebookBot.Worker.start_link(arg)
      # {FacebookBot.Worker, arg},
      worker(FacebookBot.Scheduler, []),
      {FacebookBot.Startup, name: Startup}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: FacebookBot.Supervisor]

    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    FacebookBotWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
