defmodule FacebookBotWeb.FacebookController do
  @moduledoc """
  handler facebook webhook 
  """
  use FacebookBotWeb, :controller
  alias FacebookBotWeb.FacebookHandler

  @fb_app_verify_token Application.fetch_env!(:facebook_bot, :fb_app_verify_token)

  def index(conn, _params) do
    render(conn, "index.html")
  end

  @doc """
  handler facebook webhook's challenge
  """
  def webhook(conn, %{
        "hub.challenge" => hub_challenge,
        "hub.mode" => hub_mode,
        "hub.verify_token" => hub_verify_token
      }) do
    if hub_verify_token == @fb_app_verify_token do
      conn
      |> Plug.Conn.resp(200, hub_challenge)
      |> Plug.Conn.send_resp()
    else
      IO.inspect("Mismatch hub.challenge: #{hub_challenge}")
    end
  end

  @doc """
  handler facebook webhook's event
  """
  def webhook(conn, %{"entry" => entries, "object" => "page"}) do
    Task.Supervisor.async_nolink(FacebookBot.TaskSupervisor, fn ->
      Enum.each(entries, fn entry ->
        FacebookHandler.handler_entry(entry)
      end)
    end)

    conn
    |> Plug.Conn.resp(200, "")
    |> Plug.Conn.send_resp()
  end
end
