defmodule FacebookBotWeb.Router do
  use FacebookBotWeb, :router
  alias FacebookBotWeb.Router_Header_Verify_Signature
  alias CacheBodyReader

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :facebook_api_get do
    plug :accepts, ["json"]
  end

  pipeline :facebook_api_post do
    plug Router_Header_Verify_Signature
    plug :accepts, ["json"]

    plug Plug.Parsers,
      parsers: [:urlencoded, :json],
      pass: ["text/*"],
      body_reader: {CacheBodyReader, :read_body, []},
      json_decoder: Poison
  end

  scope "/", FacebookBotWeb do
    pipe_through :browser

    get "/", PageController, :index
  end

  scope "/api/", FacebookBotWeb do
    pipe_through :facebook_api_get
    get "/webhook/", FacebookController, :webhook
  end

  scope "/api/", FacebookBotWeb do
    pipe_through :facebook_api_post
    post "/webhook/", FacebookController, :webhook
  end

  # Other scopes may use custom stacks.
  # scope "/api", FacebookBotWeb do
  #   pipe_through :api
  # end
end
