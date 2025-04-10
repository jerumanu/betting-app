defmodule Value8Bets.Betting do
  @moduledoc """
  The Betting context handles all betting-related operations.

  This includes:
  - Game management (creation, updates, listing)
  - Bet placement and processing
  - Bet history tracking
  - Profit calculations
  """

  import Ecto.Query
  alias Value8Bets.Repo
  alias Value8Bets.Betting.{Bet, Game}
  alias Value8Bets.Notifications.Email

  @doc """
  Lists all active games that are available for betting.

  ## Returns
    - List of games that haven't finished yet
  """
  def list_games do
    Game
    |> where([g], g.status != "finished")
    |> order_by([g], asc: g.game_time)
    |> Repo.all()
  end

  @doc """
  Gets a game by ID. Raises if not found.

  ## Parameters
    - id: The ID of the game to fetch

  ## Returns
    - The game struct
  ## Raises
    - Ecto.NoResultsError if game not found
  """
  def get_game!(id), do: Repo.get!(Game, id)

  @doc """
  Gets a game by ID. Returns nil if not found.

  ## Parameters
    - id: The ID of the game to fetch

  ## Returns
    - The game struct or nil
  """
  def get_game(id), do: Repo.get(Game, id)

  @doc """
  Lists all games in the system.

  ## Returns
    - List of all games, including finished ones
  """
  def list_available_games do
    Repo.all(Game)
  end

  @doc """
  Lists all bets for a given user.

  ## Parameters
    - user_id: The ID of the user or nil

  ## Returns
    - List of bets with preloaded game data
    - Empty list if user_id is nil
  """
  def list_user_bets(nil), do: []
  def list_user_bets(user_id) do
    Bet
    |> where([b], b.user_id == ^user_id)
    |> preload(:game)
    |> Repo.all()
  end

  @doc """
  Creates a new bet.

  ## Parameters
    - attrs: Map of bet attributes

  ## Returns
    - {:ok, bet} on success
    - {:error, changeset} on validation failure
  """
  def create_bet(attrs \\ %{}) do
    %Bet{}
    |> Bet.changeset(attrs)
    |> Repo.insert()
  end

  @spec cancel_bet(any(), any()) :: any()
  @doc """
  Cancels a pending bet for a user.

  ## Parameters
    - bet_id: The ID of the bet to cancel
    - user_id: The ID of the user who owns the bet

  ## Returns
    - {count, nil} where count is the number of updated records
  """
  def cancel_bet(bet_id, user_id) do
    from(b in Bet,
      where: b.id == ^bet_id and b.user_id == ^user_id and b.status == "pending"
    )
    |> Repo.update_all(set: [status: "cancelled"])
  end

  @doc """
  Gets a bet by ID. Raises if not found.

  ## Parameters
    - id: The ID of the bet to fetch

  ## Returns
    - The bet struct
  ## Raises
    - Ecto.NoResultsError if bet not found
  """
  def get_bet!(id), do: Repo.get!(Bet, id)

  @doc """
  Fetches bet history with game details for a user.
  Returns bets sorted by insertion date (newest first).

  ## Parameters
    - user_id: The ID of the user

  ## Returns
    - List of maps containing bet and game details
    - Empty list if user_id is nil
  """
  def list_user_bets_with_details(user_id) when is_integer(user_id) do
    query =
      from b in Bet,
        join: g in Game,
        on: b.game_id == g.id,
        where: b.user_id == ^user_id,
        order_by: [desc: b.inserted_at],
        select: %{
          id: b.id,
          amount: b.amount,
          odds: b.odds,
          status: b.status,
          team_picked: b.team_picked,
          potential_win: b.potential_win,
          placed_at: b.inserted_at,
          game: %{
            id: g.id,
            home_team: g.home_team,
            away_team: g.away_team,
            game_time: g.game_time,
            sport_type: g.sport_type,
            status: g.status,
            home_team_score: g.home_team_score,
            away_team_score: g.away_team_score
          }
        }

    Repo.all(query)
  end
  def list_user_bets_with_details(nil), do: []

  @doc """
  Counts the number of active (pending) bets.

  ## Returns
    - Integer count of pending bets
  """
  def count_active_bets do
    from(b in Bet,
      where: b.status == "pending"
    )
    |> Repo.aggregate(:count)
  end

  @doc """
  Creates a new game.

  ## Parameters
    - attrs: Map of game attributes

  ## Returns
    - {:ok, game} on success
    - {:error, changeset} on validation failure
  """
  def create_game(attrs \\ %{}) do
    %Game{}
    |> Game.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an existing game.

  ## Parameters
    - game: The game struct to update
    - attrs: Map of attributes to update

  ## Returns
    - {:ok, game} on success
    - {:error, changeset} on validation failure
  """
  def update_game(%Game{} = game, attrs) do
    game
    |> Game.changeset(attrs)
    |> Repo.update()
  end


@doc """
  Updates an existing bet.

  ## Parameters
    - bet: The bet struct to update
    - attrs: Map of attributes to update

  ## Returns
    - {:ok, bet} on success
    - {:error, changeset} on validation failure
  """
  def update_bet(%Bet{} = bet, attrs) do
    bet
    |> Bet.changeset(attrs)
    |> Repo.update()
  end


  @doc """
  Gets bet history for a user.

  ## Parameters
    - user_id: The ID of the user

  ## Returns
    - List of bets with preloaded game data
  """
  def get_user_bet_history(user_id) do
    Bet
    |> where([b], b.user_id == ^user_id)
    |> preload(:game)
    |> Repo.all()
  end

  @doc """
  Places a bet for a user on a specific game.

  ## Parameters
    - user_id: The ID of the user placing the bet
    - game_id: The ID of the game to bet on
    - bet_params: Map containing bet details (amount, team picked)

  ## Returns
    - {:ok, bet} on success
    - {:error, reason} on failure
  """
  def place_bet(user_id, game_id, bet_params) do
    case get_game(game_id) do
      nil ->
        {:error, "Game not found"}

      game ->
        case game.status do
          "scheduled" ->
            bet_params = Map.new(bet_params, fn {k, v} -> {to_string(k), v} end)
            {odds, normalized_team} = get_odds_for_team(game, bet_params["team_picked"])

            if is_nil(odds) do
              {:error, "Invalid team selection"}
            else
              create_bet_with_odds(user_id, game_id, bet_params, odds)
            end

          _ ->
            {:error, "Game is not available for betting"}
        end
    end
  end

  @doc """
  Gets the odds for a selected team in a game.

  ## Parameters
    - game: The game struct
    - team: The selected team name

  ## Returns
    - {odds, team_position} tuple where team_position is "home" or "away"
    - {nil, nil} if team is invalid
  """
  defp get_odds_for_team(game, team) do
    case team do
      team when team == game.home_team -> {game.odds_home, "home"}
      team when team == game.away_team -> {game.odds_away, "away"}
      _ -> {nil, nil}
    end
  end

  @doc """
  Creates a bet with calculated odds.

  ## Parameters
    - user_id: The ID of the user
    - game_id: The ID of the game
    - bet_params: The bet parameters
    - odds: The calculated odds

  ## Returns
    - {:ok, bet} on success
    - {:error, changeset} on failure
  """
  defp create_bet_with_odds(user_id, game_id, bet_params, odds) do
    attrs = %{
      user_id: user_id,
      game_id: game_id,
      amount: bet_params["amount"],
      team_picked: bet_params["team_picked"],
      odds: odds,
      status: "pending"
    }

    %Bet{}
    |> Bet.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Calculates potential winnings for a bet based on amount and odds.

  ## Parameters
    - amount: Decimal representing bet amount
    - odds: Decimal representing betting odds

  ## Returns
    - Decimal representing potential winnings
  """
  defp calculate_potential_win(amount, odds) do
    Decimal.mult(amount, odds)
  end
end
