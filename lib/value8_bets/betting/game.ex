defmodule Value8Bets.Betting.Game do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [
    :id,
    :home_team,
    :away_team,
    :game_time,
    :sport_type,
    :status,
    :home_team_score,
    :away_team_score,
    :odds_home,
    :odds_away,
    :inserted_at,
    :updated_at
  ]}
  schema "games" do
    field :home_team, :string
    field :away_team, :string
    field :game_time, :utc_datetime
    field :sport_type, :string
    field :status, :string, default: "scheduled" # scheduled, in_progress, finished
    field :home_team_score, :integer, default: 0
    field :away_team_score, :integer, default: 0
    field :odds_home, :decimal
    field :odds_away, :decimal
    
    has_many :bets, Value8Bets.Betting.Bet

    timestamps()
  end

  def changeset(game, attrs) do
    game
    |> cast(attrs, [:home_team, :away_team, :game_time, :sport_type, :status, 
                    :home_team_score, :away_team_score, :odds_home, :odds_away])
    |> validate_required([:home_team, :away_team])
    |> validate_number(:home_team_score, greater_than_or_equal_to: 0)
    |> validate_number(:away_team_score, greater_than_or_equal_to: 0)
  end
end 