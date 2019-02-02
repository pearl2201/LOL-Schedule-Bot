defmodule FacebookBotWeb.FacebookController do
  use FacebookBotWeb, :controller
  alias FacebookBotWeb.FacebookHandler

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def webhook(conn, %{
        "hub.challenge" => hub_challenge,
        "hub.mode" => hub_mode,
        "hub.verify_token" => hub_verify_token
      }) do
    if hub_verify_token == "lol_schedule_bot" do
      conn
      |> Plug.Conn.resp(200, hub_challenge)
      |> Plug.Conn.send_resp()
    else
      IO.inspect("Mismatch hub.challenge: #{hub_challenge}")
    end
  end

  def webhook(conn, %{"entry" => entries, "object" => "page"}) do
    Enum.each(entries, fn entry ->
      FacebookHandler.handler_entry(entry)
    end)

    conn
    |> Plug.Conn.resp(200, "ok")
    |> Plug.Conn.send_resp()
  end
end
