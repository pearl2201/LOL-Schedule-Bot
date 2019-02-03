defmodule FacebookBot.FaccebookBot.Subcribe do
  use Ecto.Schema
  import Ecto.Changeset


  schema "subcribe_list" do
    field :league, :string
    field :team, :string
    field :user, :string

    timestamps()
  end

  @doc false
  def changeset(subcribe, attrs) do
    subcribe
    |> cast(attrs, [:user, :team, :league])
    |> validate_required([:user, :team, :league])
  end
end
