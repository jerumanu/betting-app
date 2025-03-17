defmodule Value8Bets.Repo.Migrations.CreateGames do
  use Ecto.Migration

  def change do
    create table(:games) do
      add :home_team, :string, null: false
      add :away_team, :string, null: false
      add :game_time, :utc_datetime
      add :sport_type, :string
      add :status, :string, default: "scheduled"
      add :home_team_score, :integer, default: 0
      add :away_team_score, :integer, default: 0
      add :odds_home, :decimal
      add :odds_away, :decimal

      timestamps()
    end

    create index(:games, [:status])
    create index(:games, [:game_time])
  end
end
