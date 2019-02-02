defmodule FacebookBot.Task do
  alias FacebookBotWeb.LolHandler

  @url "https://watch.na.lolesports.com/schedule"

  def log() do
    IO.inspect("ahihi")
    IO.puts("log schedule per minute")
  end

  def fetch_data() do
    case LolHandler.fetch_league() do
      {:ok, leagues} ->
        for league <- leagues do
          case LolHandler.fetch_schedule(league["id"]) do
            {:ok, events} ->
              # IO.inspect(events)
              nil

            {:error, _} ->
              IO.inspect("Error fetch #{league["name"]}")
          end
        end

      {:error, _} ->
        IO.inspect("Error get leagues data")
    end
  end
end
