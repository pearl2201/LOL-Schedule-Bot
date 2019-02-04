defmodule FacebookBot.Startup do
  @moduledoc """
  Send Bot profile messenger
  """

  use Task

  @page_token_access Application.fetch_env!(:facebook_bot, :page_access_token)
  @uri_update_messenger_profile "https://graph.facebook.com/v2.6/me/messenger_profile?access_token=#{
                                  @page_token_access
                                }"

  def start_link(arg) do
    Task.start_link(__MODULE__, :run, [arg])
  end

  def run(arg) do
    send_messenger_profile()
  end

  def send_messenger_profile() do
    data = %{
      "get_started" => %{
        "payload" => "GET_STARTED"
      },
      "greeting" => [
        %{
          "locale" => "default",
          "text" => "Hello {{user_first_name}}! This is a tool for subcribe lol esport schedule!"
        }
      ],
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

    HTTPoison.post(@uri_update_messenger_profile, Poison.encode!(data), [
      {"Content-Type", "application/json"}
    ])
  end
end
