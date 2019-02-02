defmodule FacebookBot.Startup do
  use Task

  @page_token_access "EAAfd3Hvvjl8BAA9XsKrOJkoNZCwAiF4zcZAlYB0H2c8HkeYRZCQmZAOH4kDOM8g9PrWmljZBH0qI7ZAZBBOQcwLr20Vl2J85ykfuE5WbsPMiBiEZB1oC9WTsBagDPYuT7uv1MvQDYTXBAUNf8yYfkCW7qRq7YmZAvpJX7DQbK2PkIYgZDZD"
  @uri_update_messenger_profile "https://graph.facebook.com/v2.6/me/messenger_profile?access_token=#{
                                  @page_token_access
                                }"

  def start_link(arg) do
    Task.start_link(__MODULE__, :run, [arg])
  end

  def run(arg) do
    send_messenger_profile(:gretting)
    send_messenger_profile(:persistent_menu)
  end

  def send_messenger_profile(:gretting) do
    data = %{
      "get_started" => %{
        "payload" => "GET_STARTED"
      },
      "greeting" => [
        %{
          "locale" => "default",
          "text" => "Hello {{user_first_name}}! This is a tool for subcribe lol esport schedule!"
        }
      ]
    }

    HTTPoison.post(@uri_update_messenger_profile, Poison.encode!(data), [
      {"Content-Type", "application/json"}
    ])
  end

  def send_messenger_profile(:persistent_menu) do
    data = %{
      "persistent_menu" => [
        %{
          "locale" => "default",
          "composer_input_disabled" => true,
          "call_to_actions" => [
            %{
              "title" => "Subcribe",
              "type" => "postback",
              "payload" => "GET_LIST_TO_SUBCRIBE_PAYLOAD"
            },
            %{
              "title" => "UnSubcribe",
              "type" => "postback",
              "payload" => "GET_LIST_TO_UNSUBCRIBE_PAYLOAD"
            },
            %{
              "title" => "Result",
              "type" => "postback",
              "payload" => "GET_MATCH_RESULT_PAYLOAD"
            }
          ]
        }
      ]
    }

    HTTPoison.post(@uri_update_messenger_profile, Poison.encode!(data, pretty: true), [
      {"Content-Type", "application/json"}
    ])
  end
end
