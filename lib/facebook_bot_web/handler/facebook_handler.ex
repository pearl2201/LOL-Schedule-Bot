defmodule FacebookBotWeb.FacebookHandler do
  @moduledoc """
  Handler Entry Facebook
  """

  alias FacebookBotWeb.LolHandler
  alias FacebookBot.FaccebookBot.Subcribe_Manager

  @page_token_access Application.fetch_env!(:facebook_bot, :page_access_token)
  @uri_messenger "https://graph.facebook.com/v2.6/me/messages?access_token=#{@page_token_access}"

  def handler_entry([]) do
    nil
  end

  @doc """
  handler entry of facebook webhook
  """
  def handler_entry(entry) do
    Enum.each(entry["messaging"], fn message ->
      cond do
        message["postback"] ->
          cmd = message["postback"]["payload"]
          senderId = message["sender"]["id"]

          cond do
            cmd == "GET_LIST_TO_UNSUBCRIBE_PAYLOAD" ->
              send_league_list(:unsubcribe, senderId)

            cmd == "GET_LIST_TO_SUBCRIBE_PAYLOAD" ->
              send_league_list(:subcribe, senderId)

            cmd == "GET_MATCH_RESULT_PAYLOAD" ->
              send_league_list(:result, senderId)

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

              if action == "subcribe" do
                send_team_list(:subcribe, senderId, idLeague)
              else
                send_team_list(:unsubcribe, senderId, idLeague)
              end

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
          IO.inspect("Don't know type command")
      end
    end)
  end

  @doc """
  subcribe team with data as parameter
  """
  def subcribe_team(recipientId, codeTeam, codeLeague) do
    Subcribe_Manager.insert(recipientId, codeLeague, codeTeam)

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

  @doc """
  unsubcribe team with data as parameter
  """
  def unsubcribe_team(recipientId, codeTeam, codeLeague) do
    Subcribe_Manager.insert(recipientId, codeLeague, codeTeam)

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

  @doc """
  send greeting tutorial
  """
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

  @doc """
  send list league to subcribe
  """
  def send_league_list(:subcribe, recipientId) do
    {:ok, leagues} = LolHandler.fetch_league()
    messageData = build_league_list_messeage(recipientId, "subcribe", leagues)
    callSendAPI(messageData)
  end

  @doc """
  send list league to unsubcribe
  """
  def send_league_list(:unsubcribe, recipientId) do
    {:ok, leagues} = LolHandler.fetch_league()
    subcribed_leagues_code = Subcribe_Manager.query_subcribed_leagues(recipientId)

    subcribed_leagues =
      Enum.filter(leagues, fn league ->
        Enum.any?(subcribed_leagues_code, fn x -> league["name"] == x end)
      end)

    messageData = build_league_list_messeage(recipientId, "unsubcribe", subcribed_leagues)
    callSendAPI(messageData)
  end

  @doc """
  send list league to getresult
  """
  def send_league_list(:result, recipientId) do
    {:ok, leagues} = LolHandler.fetch_league()
    messageData = build_league_list_messeage(recipientId, "result", leagues)
    callSendAPI(messageData)
  end

  @doc """
  build message to send all league for action
  """
  def build_league_list_messeage(recipientId, type_action, leagues) do
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

  @doc """
  send list unsubcribed team in a league to subcribe
  """
  def send_team_list(:subcribe, recipientId, idLeague) do
    {:ok, leagues} = LolHandler.fetch_league()
    league = Enum.find(leagues, fn x -> x["id"] == "#{idLeague}" end)
    {:ok, teams} = LolHandler.fetch_league(idLeague)

    subcribed_teams_code = Subcribe_Manager.query_subcribed_teams(recipientId, league["name"])

    unsubcribed_teams =
      Enum.filter(teams, fn team ->
        Enum.all?(subcribed_teams_code, fn x -> team["code"] != x.team end)
      end)

    messageData =
      build_message_team_list(recipientId, "subcribe", league["name"], unsubcribed_teams)

    callSendAPI(messageData)
  end

  @doc """
  send list subcribeb team in a league to unsubcribe
  """
  def send_team_list(:unsubcribe, recipientId, idLeague) do
    {:ok, leagues} = LolHandler.fetch_league()
    league = Enum.find(leagues, fn x -> x["id"] == "#{idLeague}" end)
    {:ok, teams} = LolHandler.fetch_league(idLeague)

    subcribed_teams_code = Subcribe_Manager.query_subcribed_teams(recipientId, league["name"])

    subcribed_teams =
      Enum.filter(teams, fn team ->
        Enum.any?(subcribed_teams_code, fn x -> team["code"] == x.team end)
      end)

    messageData =
      build_message_team_list(recipientId, "unsubcribe", league["name"], subcribed_teams)

    callSendAPI(messageData)
  end

  @doc """
  build message to send list team for action
  """
  def build_message_team_list(recipientId, type_action, codeLeague, teams) do
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
                "payload" => "team-#{type_action}-#{codeLeague}-#{team["code"]}",
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

  @doc """
  send recent result of a league to sender
  """
  def send_response_list_to_get_result(recipientId, leagueID) do
    {:ok, events} = LolHandler.fetch_schedule(leagueID)

    messageText =
      events
      |> Enum.filter(fn x -> x["state"] == "completed" end)
      |> Enum.map(fn event ->
        team1 = Enum.at(event["match"]["teams"], 0)
        team2 = Enum.at(event["match"]["teams"], 1)

        "#{team1["code"]} #{team1["result"]["outcome"]} - 
        #{team1["result"]["outcome"]} #{team1["code"]}\n"
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

  @doc """
  notify schedule to subcribe
  """
  def notify_schedule() do
    {:ok, leagues} = LolHandler.fetch_league()

    Enum.each(leagues, fn league ->
      {:ok, events} = LolHandler.fetch_schedule(league["id"])

      events_notify =
        events
        |> Enum.filter(fn x ->
          {:ok, startDatetime, 0} = DateTime.from_iso8601(x["startTime"])
          currentDatetime = DateTime.utc_now()

          DateTime.compare(currentDatetime, startDatetime) != :gt and
            DateTime.diff(currentDatetime, startDatetime) <= 30 and x["state"] == "unstarted"
        end)

      events_notify
      |> Enum.each(fn event ->
        team1 = Enum.at(event["match"]["teams"], 0)
        team2 = Enum.at(event["match"]["teams"], 1)

        subcribers = Subcribe_Manager.query(event["league"]["name"], team1["code"], team2["code"])

        Enum.each(subcribers, fn subcriber ->
          messageData = %{
            "recipient" => %{
              "id" => subcriber.user
            },
            "message" => %{
              "text" =>
                "#{event["startTime"]}: #{team1["code"]} vs #{team2["code"]}.\n Check video stream at https://www.youtube.com/channel/UCvqRdlKsE5Q8mf8YXbdIJLw",
              "metadata" => "lol_notify_schedule"
            }
          }

          callSendAPI(messageData)
        end)
      end)
    end)
  end

  @doc """
  send post request to facebook messenger graph api
  """
  def callSendAPI(messageData) do
    HTTPoison.post(
      @uri_messenger,
      Poison.encode!(messageData, pretty: true),
      [
        {"Content-Type", "application/json"}
      ]
    )
  end
end
