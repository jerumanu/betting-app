# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Value8Bets.Repo.insert!(%Value8Bets.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Value8Bets.Repo
alias Value8Bets.Betting.{Bet, Game}
alias Value8Bets.Accounts.User

# First, clean up existing data in the correct order
Repo.delete_all(Bet)

# Delete all games
Repo.delete_all(Game)

# Helper module for time calculations
defmodule Seeds.Helpers do
  def future_time(days, hours) do
    DateTime.utc_now()
    |> DateTime.add(days * 24 * 60 * 60 + hours * 60 * 60, :second)
    |> DateTime.truncate(:second)
  end
end

# Premier League matches
football_games = [
  %{
    home_team: "Manchester City",
    away_team: "Arsenal",
    game_time: Seeds.Helpers.future_time(1, 3),
    sport_type: "Football",
    odds_home: "1.85",
    odds_away: "4.20"
  },
  %{
    home_team: "Liverpool",
    away_team: "Manchester United",
    game_time: Seeds.Helpers.future_time(1, 6),
    sport_type: "Football",
    odds_home: "1.65",
    odds_away: "4.50"
  },
  %{
    home_team: "Chelsea",
    away_team: "Tottenham",
    game_time: Seeds.Helpers.future_time(2, 2),
    sport_type: "Football",
    odds_home: "2.10",
    odds_away: "3.40"
  },
  %{
    home_team: "Newcastle",
    away_team: "Aston Villa",
    game_time: Seeds.Helpers.future_time(2, 5),
    sport_type: "Football",
    odds_home: "1.95",
    odds_away: "3.80"
  },
  %{
    home_team: "Brighton",
    away_team: "West Ham",
    game_time: Seeds.Helpers.future_time(3, 2),
    sport_type: "Football",
    odds_home: "2.20",
    odds_away: "3.30"
  },
  %{
    home_team: "Brentford",
    away_team: "Crystal Palace",
    game_time: Seeds.Helpers.future_time(3, 5),
    sport_type: "Football",
    odds_home: "2.40",
    odds_away: "3.00"
  },
  %{
    home_team: "Fulham",
    away_team: "Everton",
    game_time: Seeds.Helpers.future_time(4, 2),
    sport_type: "Football",
    odds_home: "2.15",
    odds_away: "3.40"
  },
  %{
    home_team: "Burnley",
    away_team: "Sheffield United",
    game_time: Seeds.Helpers.future_time(4, 5),
    sport_type: "Football",
    odds_home: "1.90",
    odds_away: "4.00"
  },
  %{
    home_team: "Nottingham Forest",
    away_team: "Luton Town",
    game_time: Seeds.Helpers.future_time(5, 2),
    sport_type: "Football",
    odds_home: "2.00",
    odds_away: "3.75"
  },
  %{
    home_team: "Wolves",
    away_team: "Bournemouth",
    game_time: Seeds.Helpers.future_time(5, 5),
    sport_type: "Football",
    odds_home: "2.25",
    odds_away: "3.20"
  }
]

# Insert all games
games = Enum.map(football_games, fn game ->
  %Game{}
  |> Game.changeset(game)
  |> Repo.insert!()
end)

IO.puts("Database seeded with #{length(football_games)} football matches!")

# Create or get test user
test_user = case Repo.get_by(User, email: "test@example.com") do
  nil ->
    {:ok, user} = Value8Bets.Accounts.register_user(%{
      "email" => "test@example.com",
      "password" => "password123",
      "role" => "user"
    })
    user
  existing_user -> existing_user
end

# Create sample bets
bets = [
  %{
    amount: Decimal.new("100.00"),
    odds: Decimal.new("1.85"),
    status: "pending",
    team_picked: hd(games).home_team,
    user_id: test_user.id,
    game_id: hd(games).id,
    potential_win: Decimal.mult(Decimal.new("100.00"), Decimal.new("1.85"))
  },
  %{
    amount: Decimal.new("50.00"),
    odds: Decimal.new("4.20"),
    status: "pending",
    team_picked: Enum.at(games, 1).away_team,
    user_id: test_user.id,
    game_id: Enum.at(games, 1).id,
    potential_win: Decimal.mult(Decimal.new("50.00"), Decimal.new("4.20"))
  },
  %{
    amount: Decimal.new("75.00"),
    odds: Decimal.new("2.10"),
    status: "won",
    team_picked: Enum.at(games, 2).home_team,
    user_id: test_user.id,
    game_id: Enum.at(games, 2).id,
    potential_win: Decimal.mult(Decimal.new("75.00"), Decimal.new("2.10"))
  },
  %{
    amount: Decimal.new("25.00"),
    odds: Decimal.new("3.40"),
    status: "lost",
    team_picked: Enum.at(games, 3).away_team,
    user_id: test_user.id,
    game_id: Enum.at(games, 3).id,
    potential_win: Decimal.mult(Decimal.new("25.00"), Decimal.new("3.40"))
  },
  %{
    amount: Decimal.new("150.00"),
    odds: Decimal.new("1.95"),
    status: "cancelled",
    team_picked: Enum.at(games, 4).home_team,
    user_id: test_user.id,
    game_id: Enum.at(games, 4).id,
    potential_win: Decimal.mult(Decimal.new("150.00"), Decimal.new("1.95"))
  }
]

# Insert all bets
Enum.each(bets, fn bet_attrs ->
  %Bet{}
  |> Bet.changeset(bet_attrs)
  |> Repo.insert!()
end)

IO.puts("Sample bets created successfully!")

# Create or get superuser
superuser = case Repo.get_by(User, email: "superuser@example.com") do
  nil ->
    {:ok, user} = Value8Bets.Accounts.register_user(%{
      "email" => "superuser@example.com",
      "password" => "superuser123",
      "role" => "superuser"
    })
    user
  existing_user -> existing_user
end

# Create or get admin
admin = case Repo.get_by(User, email: "admin@example.com") do
  nil ->
    {:ok, user} = Value8Bets.Accounts.register_user(%{
      "email" => "admin@example.com",
      "password" => "admin123",
      "role" => "admin"
    })
    user
  existing_user -> existing_user
end

IO.puts("Seeds completed successfully!")
