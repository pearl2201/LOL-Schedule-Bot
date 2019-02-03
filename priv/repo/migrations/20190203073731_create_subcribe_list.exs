defmodule FacebookBot.Repo.Migrations.CreateSubcribeList do
  use Ecto.Migration

  def change do
    create table(:subcribe_list) do
      add :user, :string
      add :team, :string
      add :league, :string

      timestamps()
    end

  end
end
