defmodule FacebookBotWeb.FacebookHandler do
  alias FacebookBotWeb.LolHandler

  @page_token_access "EAAfd3Hvvjl8BAA9XsKrOJkoNZCwAiF4zcZAlYB0H2c8HkeYRZCQmZAOH4kDOM8g9PrWmljZBH0qI7ZAZBBOQcwLr20Vl2J85ykfuE5WbsPMiBiEZB1oC9WTsBagDPYuT7uv1MvQDYTXBAUNf8yYfkCW7qRq7YmZAvpJX7DQbK2PkIYgZDZD"
  @uri_messenger "https://graph.facebook.com/v2.6/me/messages?access_token=#{@page_token_access}"

  def handler_entry([]) do
    nil
  end

  def handler_entry(entry) do
    IO.inspect(entry)
    IO.inspect(entry["messaging"])

    Enum.each(entry["messaging"], fn message ->
      IO.inspect(message)

      cond do
        message["postback"] ->
          cmd = message["postback"]["payload"]
          senderId = message["sender"]["id"]

          case cmd do
            "GET_LIST_TO_UNSUBCRIBE_PAYLOAD" ->
              send_response_list_to_unsubcribe(senderId)

            "GET_LIST_TO_SUBCRIBE_PAYLOAD" ->
              send_response_list_to_subcribe(senderId)

            "GET_MATCH_RESULT_PAYLOAD" ->
              send_response_list_to_get_result(senderId)

            _ ->
              IO.inspect("No identify command")
          end
      end
    end)
  end

  def build_element(leagues, id) do
    league = Enum.at(leagues, id)

    # %{
    #   "content_type" => "text",
    #   "title" => league["slug"],
    #   "payload" => "GET_TEAM_TO_SUBCRIBE_LANGUAGE=#{league["id"]}",
    #   "image_url" => league["image"]
    # }

    %{
      "title" => league["slug"],
      "image_url" => league["image"],
      "subtitle" => league["region"],
      "buttons" => [
        %{
          "type" => "postback",
          "payload" => "GET_TEAM_TO_SUBCRIBE_LANGUAGE=#{league["id"]}",
          "title" => league["slug"]
        }
      ]
    }
  end

  def send_response_list_to_subcribe(recipientId) do
    {:ok, leagues} = LolHandler.fetch_league()
    IO.inspect(leagues)

    buttons =
      Enum.chunk_every(leagues, 3)
      |> Enum.with_index()
      |> Enum.map(fn {x, k} ->
        start_index = k * 3
        end_index = k * 3 + 3

        %{
          "title" => "League #{start_index}-#{end_index}",
          "buttons" =>
            Enum.map(x, fn league ->
              %{
                "type" => "postback",
                "payload" => "GET_TEAM_TO_SUBCRIBE_LANGUAGE=#{league["id"]}",
                "title" => league["slug"]
              }
            end)
        }
      end)

    IO.inspect(buttons)

    messageData = %{
      "recipient" => %{
        "id" => recipientId
      },
      "message" => %{
        "attachment" => %{
          "type" => "template",
          "payload" => %{
            "template_type" => "generic",
            "elements" => buttons
          }
        }
      }
    }

    callSendAPI(messageData)
  end

  def send_response_list_to_unsubcribe(recipientId) do
    messageData = %{
      "recipient" => %{
        "id" => recipientId
      },
      "message" => %{
        "attachment" => %{
          "type" => "template",
          "payload" => %{
            "template_type" => "button",
            "text" => "This is test text",
            "buttons" => [
              %{
                "type" => "web_url",
                "url" => "https://www.oculus.com/en-us/rift/",
                "title" => "Open Web URL"
              },
              %{
                "type" => "postback",
                "title" => "Trigger Postback",
                "payload" => "DEVELOPER_DEFINED_PAYLOAD"
              },
              %{
                "type" => "phone_number",
                "title" => "Call Phone Number",
                "payload" => "+16505551234"
              }
            ]
          }
        }
      }
    }

    callSendAPI(messageData)
  end

  def send_response_list_to_get_result(recipientId) do
    messageData = %{
      "recipient" => %{
        "id" => recipientId
      },
      "message" => %{
        "attachment" => %{
          "type" => "template",
          "payload" => %{
            "template_type" => "button",
            "text" => "This is test text",
            "buttons" => [
              %{
                "type" => "web_url",
                "url" => "https://www.oculus.com/en-us/rift/",
                "title" => "Open Web URL"
              },
              %{
                "type" => "postback",
                "title" => "Trigger Postback",
                "payload" => "DEVELOPER_DEFINED_PAYLOAD"
              },
              %{
                "type" => "phone_number",
                "title" => "Call Phone Number",
                "payload" => "+16505551234"
              }
            ]
          }
        }
      }
    }

    callSendAPI(messageData)
  end

  def callSendAPI(messageData) do
    IO.inspect(@uri_messenger)

    HTTPoison.post(
      @uri_messenger,
      Poison.encode!(messageData, pretty: true),
      [
        {"Content-Type", "application/json"}
      ]
    )
    |> IO.inspect()

    # request({
    #   uri: 'https://graph.facebook.com/v2.6/me/messages',
    #   qs: { access_token: PAGE_ACCESS_TOKEN },
    #   method: 'POST',
    #   json: messageData

    # }, function (error, response, body) {
    #   if (!error && response.statusCode == 200) {
    #     var recipientId = body.recipient_id;
    #     var messageId = body.message_id;

    #     if (messageId) {
    #       console.log("Successfully sent message with id %s to recipient %s", 
    #         messageId, recipientId);
    #     } else {
    #     console.log("Successfully called Send API for recipient %s", 
    #       recipientId);
    #     }
    #   } else {
    #     console.error("Failed calling Send API", response.statusCode, response.statusMessage, body.error);
    #   }
    # });  
  end
end
