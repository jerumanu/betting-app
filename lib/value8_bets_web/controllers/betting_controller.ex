defmodule Value8BetsWeb.BettingController do
  use Value8BetsWeb, :controller
  alias Value8Bets.Betting
  alias Value8BetsWeb.Auth.Guardian

  def index(conn, params) do
    games = Betting.list_available_games()
    json(conn, %{
      data: Enum.map(games, fn game ->
        %{
          id: game.id,
          home_team: game.home_team,
          away_team: game.away_team,
          game_time: game.game_time,
          sport_type: game.sport_type,
          status: game.status,
          odds_home: Decimal.to_string(game.odds_home),
          odds_away: Decimal.to_string(game.odds_away)
        }
      end)
    })
  end

  def show(conn, %{"id" => id}) do
    case Betting.get_game(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Game not found"})
      
      game ->
        json(conn, %{
          data: %{
            id: game.id,
            home_team: game.home_team,
            away_team: game.away_team,
            game_time: game.game_time,
            sport_type: game.sport_type,
            status: game.status,
            odds_home: Decimal.to_string(game.odds_home),
            odds_away: Decimal.to_string(game.odds_away)
          }
        })
    end
  end

  def history(conn, _params) do
    case Guardian.get_current_user(conn) do
      {:ok, user_data} ->
        bets = Betting.get_user_bet_history(user_data.id)
        json(conn, %{
          data: Enum.map(bets, fn bet ->
            %{
              id: bet.id,
              amount: bet.amount,
              odds: bet.odds,
              status: bet.status,
              team_picked: bet.team_picked,
              potential_win: bet.potential_win,
              game: %{
                id: bet.game.id,
                home_team: bet.game.home_team,
                away_team: bet.game.away_team,
                game_time: bet.game.game_time,
                status: bet.game.status
              }
            }
          end)
        })

      {:error, _} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Unauthorized"})
    end
  end

  def place_bet(conn, %{"id" => game_id, "bet" => bet_params}) do
    case Guardian.get_current_user(conn) do
      {:ok, user_data} ->
        case Betting.place_bet(user_data.id, game_id, bet_params) do
          {:ok, bet} ->
            conn
            |> put_status(:created)
            |> json(%{
              data: %{
                id: bet.id,
                amount: bet.amount,
                odds: bet.odds,
                status: bet.status,
                team_picked: bet.team_picked,
                potential_win: bet.potential_win
              }
            })

          {:error, %Ecto.Changeset{} = changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{errors: format_changeset_errors(changeset)})

          {:error, message} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{error: message})
        end

      {:error, _} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Unauthorized"})
    end
  end

  def user_bets(conn, params) do
    case Guardian.get_current_user(conn) do
      {:ok, user_data} ->
        page = params["page"] || 1
        per_page = params["per_page"] || 10
        
        bets = Betting.list_user_bets_with_details(user_data.id)
        |> Enum.map(fn bet -> 
          %{
            id: bet.id,
            amount: Decimal.to_string(bet.amount),
            odds: Decimal.to_string(bet.odds),
            status: bet.status,
            team_picked: bet.team_picked,
            potential_win: Decimal.to_string(bet.potential_win),
            placed_at: bet.placed_at,
            game: %{
              id: bet.game.id,
              home_team: bet.game.home_team,
              away_team: bet.game.away_team,
              game_time: bet.game.game_time,
              sport_type: bet.game.sport_type,
              status: bet.game.status,
              home_team_score: bet.game.home_team_score,
              away_team_score: bet.game.away_team_score
            }
          }
        end)

        json(conn, %{
          data: %{
            bets: bets,
            pagination: %{
              total_count: length(bets),
              page: page,
              per_page: per_page
            }
          }
        })

      {:error, _} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Unauthorized"})
    end
  end

  def get_bet_details(conn, %{"id" => id}) do
    case Betting.get_game(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Game not found"})
      
      game ->
        case game.status do
          "scheduled" ->
            json(conn, %{
              data: %{
                id: game.id,
                home_team: game.home_team,
                away_team: game.away_team,
                game_time: game.game_time,
                sport_type: game.sport_type,
                status: game.status,
                odds: %{
                  home: %{
                    team: game.home_team,
                    odds: Decimal.to_string(game.odds_home)
                  },
                  away: %{
                    team: game.away_team,
                    odds: Decimal.to_string(game.odds_away)
                  }
                }
              }
            })

          _ ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{error: "Game is not available for betting"})
        end
    end
  end

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end 