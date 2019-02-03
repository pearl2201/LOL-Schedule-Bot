defmodule FacebookBotWeb.FacebookHandler do
  alias FacebookBotWeb.LolHandler

  @page_token_access Application.fetch_env!(:facebook_bot, :page_access_token)
  @uri_messenger "https://graph.facebook.com/v2.6/me/messages?access_token=#{@page_token_access}"

  def handler_entry([]) do
    nil
  end

  def handler_entry(entry) do
    # IO.inspect(entry)
    # IO.inspect(entry["messaging"])

    Enum.each(entry["messaging"], fn message ->
      cond do
        message["postback"] ->
          cmd = message["postback"]["payload"]
          senderId = message["sender"]["id"]

          cond do
            cmd == "GET_LIST_TO_UNSUBCRIBE_PAYLOAD" ->
              send_league_list(senderId, "unsubcribe")

            cmd == "GET_LIST_TO_SUBCRIBE_PAYLOAD" ->
              send_league_list(senderId, "subcribe")

            cmd == "GET_MATCH_RESULT_PAYLOAD" ->
              send_league_list(senderId, "result")

            cmd == "GET_STARTED" ->
              send_tutorial(senderId)

            String.starts_with?(cmd, "get_league-result") ->
              cmd_split = cmd |> String.split("-")
              idLeague = cmd_split |> Enum.at(2)
              action = cmd_split |> Enum.at(1)
              send_response_list_to_get_result(senderId, idLeague)

            String.starts_with?(cmd, "get_league") ->
              cmd_split = cmd |> String.split("-")
              idLeague = cmd_split |> Enum.at(2)
              action = cmd_split |> Enum.at(1)
              send_team_list(senderId, action, idLeague)

            String.starts_with?(cmd, "team-") ->
              cmd_split = cmd |> String.split("-")
              codeTeam = cmd_split |> Enum.at(3)
              codeLeague = cmd_split |> Enum.at(2)
              action = cmd_split |> Enum.at(1)

              if action == "subcribe" do
                subcribe_team(senderId, codeTeam, codeLeague)
              else
                unsubcribe_team(senderId, codeTeam, codeLeague)
              end

            true ->
              IO.inspect("No identify command")
          end

        true ->
          IO.insecpt("Don't know type command")
      end
    end)
  end

  def subcribe_team(recipientId, codeTeam, codeLeague) do
    messageData = %{
      "recipient" => %{
        "id" => recipientId
      },
      "message" => %{
        "text" => "subcribe success",
        "metadata" => "lol_result"
      }
    }

    callSendAPI(messageData)
  end

  def unsubcribe_team(recipientId, codeTeam, codeLeague) do
    messageData = %{
      "recipient" => %{
        "id" => recipientId
      },
      "message" => %{
        "text" => "unsubcribe success",
        "metadata" => "lol_result"
      }
    }

    callSendAPI(messageData)
  end

  def send_tutorial(recipientId) do
    messageData = %{
      "recipient" => %{
        "id" => recipientId
      },
      "message" => %{
        "attachment" => %{
          "type" => "template",
          "payload" => %{
            "template_type" => "button",
            "text" => "What do you want to do next?",
            "buttons" => [
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
        }
      }
    }

    callSendAPI(messageData)
  end

  def send_league_list(recipientId, type_action) do
    {:ok, leagues} = LolHandler.fetch_league()

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
                "payload" => "get_league-#{type_action}-#{league["id"]}",
                "title" => league["slug"]
              }
            end)
        }
      end)

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

  def send_team_list(recipientId, type_action, idLeague) do
    messageData = build_message_team_list(recipientId, type_action, idLeague)
    callSendAPI(messageData)
  end

  def build_message_team_list(recipientId, type_action, idLeague) do
    {:ok, leagues} = LolHandler.fetch_league()
    IO.inspect(leagues)
    league = Enum.find(leagues, fn x -> x["id"] == "#{idLeague}" end)
    {:ok, teams} = LolHandler.fetch_league(idLeague)

    IO.inspect(league)

    buttons =
      Enum.chunk_every(teams, 3)
      |> Enum.with_index()
      |> Enum.map(fn {x, k} ->
        start_index = k * 3
        end_index = k * 3 + 3

        %{
          "title" => "Team #{start_index}-#{end_index}",
          "buttons" =>
            Enum.map(x, fn team ->
              %{
                "type" => "postback",
                "payload" => "team-#{type_action}-#{league["name"]}-#{team["code"]}",
                "title" => team["code"]
              }
            end)
        }
      end)

    %{
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
  end

  def send_response_list_to_get_result(recipientId, leagueID) do
    events = LolHandler.fetch_schedule(leagueID)

    messageText =
      events
      |> Enum.any(fn x -> x["state"] == "completed" end)
      |> Enum.map(fn event ->
        team1 = Enum.at(event["match"]["teams"], 0)
        team2 = Enum.at(event["match"]["teams"], 1)

        "#{team1["code"]} #{team1["result"]["outcome"]} - #{team1["result"]["outcome"]} #{
          team1["code"]
        } "
      end)
      |> Enum.join()

    messageData = %{
      "recipient" => %{
        "id" => recipientId
      },
      "message" => %{
        "text" => messageText,
        "metadata" => "lol_result"
      }
    }

    callSendAPI(messageData)
  end

  def callSendAPI(messageData) do
    HTTPoison.post(
      @uri_messenger,
      Poison.encode!(messageData, pretty: true),
      [
        {"Content-Type", "application/json"}
      ]
    )
    |> IO.inspect()
  end
end
