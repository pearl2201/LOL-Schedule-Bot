defmodule FacebookBot.FaccebookBot.Subcribe_Manager do
  @moduledoc """
  The boundary for the Blog system.
  """

  import Ecto.Query, warn: false
  alias FacebookBot.Repo
  alias FacebookBot.FaccebookBot.Subcribe

  def insert(idUser, codeLeague, codeTeam) do
    case Subcribe
         |> Repo.get_by(user: idUser, league: codeLeague, team: codeTeam) do
      nil ->
        %Subcribe{}
        |> Subcribe.changeset(%{
          "user" => idUser,
          "league" => codeLeague,
          "team" => codeTeam
        })
        |> Repo.insert()

      subcribe ->
        nil
    end
  end

  def delete(idUser, codeLeague, codeTeam) do
    case Subcribe
         |> Repo.get_by(user: idUser, league: codeLeague, team: codeTeam) do
      nil ->
        false

      subcribe ->
        Repo.delete(subcribe)
    end
  end

  def query(codeLeague, codeTeam) do
    Subcribe
    |> Repo.get_by(league: codeLeague, team: codeTeam)
  end

  def query_subcribed_leagues(user) do
    query = from(p in Subcribe, where: p.user == user, distinct: p.league, select: p.league)
    Repo.all(query)
  end

  def query_subcribed_teams(user, league) do
    from(
      p in Subcribe,
      where: p.user == user and p.league == league
    )

    Repo.all(query)
  end
end
