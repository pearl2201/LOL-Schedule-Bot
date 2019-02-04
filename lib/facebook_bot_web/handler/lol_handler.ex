defmodule FacebookBotWeb.LolHandler do
  @x_api_key Application.fetch_env!(:facebook_bot, :x_api_key)
  @url_league "https://prod-relapi.ewp.gg/persisted/gw/getLeagues?hl=en-US"
  @url_schedule "https://prod-relapi.ewp.gg/persisted/gw/getSchedule?hl=en-US&leagueId="
  @url_tournaments "https://prod-relapi.ewp.gg/persisted/gw/getTournamentsForLeague?hl=en-US&leagueId="
  @url_standing "https://prod-relapi.ewp.gg/persisted/gw/getStandings?hl=en-US&tournamentId="

  def fetch_league() do
    case HTTPoison.get(@url_league, [{"x-api-key", @x_api_key}]) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        response_json = Poison.decode!(body)
        leagues = response_json["data"]["leagues"]
        {:ok, leagues}

      {:ok, %HTTPoison.Response{status_code: 404}} ->
        {:error, "404 not found"}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  def fetch_schedule(regionID) do
    case HTTPoison.get("#{@url_schedule}#{regionID}", [{"x-api-key", @x_api_key}]) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        response_json = Poison.decode!(body)
        events = response_json["data"]["schedule"]["events"]

        {:ok, events}

      {:ok, %HTTPoison.Response{status_code: 404}} ->
        {:error, "404 not found"}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  def fetch_tournaments(regionID) do
    case HTTPoison.get("#{@url_tournaments}#{regionID}", [{"x-api-key", @x_api_key}]) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        response_json = Poison.decode!(body)
        tournaments = Enum.at(response_json["data"]["leagues"], 0)["tournaments"]

        {:ok, tournaments}

      {:ok, %HTTPoison.Response{status_code: 404}} ->
        {:error, "404 not found"}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  def fetch_standing(tournamentID) do
    case HTTPoison.get("#{@url_standing}#{tournamentID}", [{"x-api-key", @x_api_key}]) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        response_json = Poison.decode!(body)
        # events = response_json["data"]["schedule"]["events"]

        {:ok, response_json}

      {:ok, %HTTPoison.Response{status_code: 404}} ->
        {:error, "404 not found"}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  def fetch_teaminfo(teamcode) when is_binary(teamcode) do
    # IO.puts("hihihih")
    {:ok, leagues} = fetch_league()
    # IO.inspect(leagues)

    m =
      Enum.find(leagues, fn league ->
        {:ok, tournaments} = fetch_tournaments(league["id"])

        Enum.find(tournaments, fn tournament ->
          {:ok, standings_json} = fetch_standing(tournament["id"])

          standings = standings_json["data"]["standings"]

          if standings do
            Enum.find(standings, fn standing ->
              Enum.find(standing["stages"], fn stage ->
                # IO.inspect(stage)

                Enum.find(stage["sections"], fn section ->
                  # IO.inspect(section)
                  rankings = section["rankings"]

                  if rankings do
                    Enum.find(rankings, fn ranking ->
                      # IO.inspect(ranking)

                      Enum.find(ranking["teams"], fn team ->
                        if team["code"] == teamcode do
                          IO.inspect(team)
                          team
                        else
                          # IO.inspect(team["name"])
                          nil
                        end
                      end)
                    end)
                  end
                end)
              end)
            end)
          end
        end)
      end)
  end

  @doc """
  Only fetch first section of regular season
  """
  def fetch_league(leagueID) do
    {:ok, tournaments} = fetch_tournaments(leagueID)

    tournament =
      Enum.find(tournaments, fn tournament ->
        {:ok, startDate} = Date.from_iso8601(tournament["startDate"])
        {:ok, endDate} = Date.from_iso8601(tournament["endDate"])
        currentDate = Date.utc_today()

        Date.compare(currentDate, startDate) != :lt and Date.compare(currentDate, endDate) != :gt
      end)

    {:ok, standings_json} = fetch_standing(tournament["id"])

    standings = standings_json["data"]["standings"]

    if standings do
      standing = Enum.at(standings, 0)
      stage = Enum.at(standing["stages"], 0)
      section = Enum.at(stage["sections"], 0)
      rankings = section["rankings"]

      if rankings do
        teams =
          for ranking <- rankings do
            ranking["teams"]
          end

        {:ok, Enum.reduce(teams, [], fn x, acc -> x ++ acc end)}
      else
        {:error}
      end
    else
      {:error}
    end
  end
end
