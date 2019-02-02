defmodule FacebookBotWeb.PageController do
  use FacebookBotWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
