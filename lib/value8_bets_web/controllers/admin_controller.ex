defmodule Value8BetsWeb.AdminController do
  @moduledoc """
  Handles all admin-related HTTP requests.

  This controller provides endpoints for:
  - User management
  - Profit tracking
  - Game configuration (for superusers)
  - Admin role management
  """

  use Value8BetsWeb, :controller

  alias Value8Bets.Accounts
  alias Value8Bets.Betting
  alias Decimal

  # Private helper functions
  defp calculate_total_profits(profits) do
    profits
    |> Enum.map(& &1.total_profit)
    |> Enum.reduce(Decimal.new("0"), &Decimal.add/2)
    |> Decimal.to_string()
  end

  defp count_new_users(users) do
    seven_days_ago = NaiveDateTime.utc_now() |> NaiveDateTime.add(-7 * 24 * 60 * 60)
    
    users
    |> Enum.filter(fn user -> 
      NaiveDateTime.compare(user.inserted_at, seven_days_ago) == :gt
    end)
    |> length()
  end

  defp count_active_bets(users) do
    users
    |> Enum.map(& &1.total_bets)
    |> Enum.sum()
  end

  @doc """
  Displays the admin dashboard with key metrics.

  ## Parameters
    - conn: Connection struct
    - _params: Unused parameters

  ## Returns
    - JSON response with dashboard data
  """
  def dashboard(conn, _params) do
    # Calculate key metrics
    users = Accounts.list_users_with_stats()
    profits = Accounts.calculate_profits()
    total_profits = calculate_total_profits(profits)
    new_users = count_new_users(users)
    active_bets = count_active_bets(users)

    json(conn, %{
      data: %{
        users_count: length(users),
        total_profits: total_profits,
        recent_activity: %{
          new_users: new_users,
          active_bets: active_bets
        }
      }
    })
  end

  @doc """
  Lists all users with their statistics and roles.
  
  ## Returns
    - JSON response with users list including roles and stats
  """
  def list_users(conn, _params) do
    users = Accounts.list_users_with_stats()
            |> Enum.map(fn user ->
              %{
                id: user.id,
                email: user.email,
                role: user.role,
                is_active: user.is_active,
                total_bets: user.total_bets,
                total_amount_bet: user.total_amount_bet && Decimal.to_string(user.total_amount_bet),
                total_winnings: user.total_winnings && Decimal.to_string(user.total_winnings),
                created_at: user.inserted_at
              }
            end)
    
    json(conn, %{data: users})
  end

  def user_details(conn, %{"id" => user_id}) do
    case Integer.parse(user_id) do
      {id, _} ->
        case Accounts.get_user_with_bet_history(id) do
          nil ->
            conn
            |> put_status(:not_found)
            |> json(%{error: "User not found"})

          user ->
            # Convert user and bets to plain maps with selected fields
            user_data = %{
              id: user.id,
              email: user.email,
              is_admin: user.is_admin,
              is_superuser: user.is_superuser,
              registered_at: user.inserted_at,
              bets: Enum.map(user.bets, fn bet ->
                %{
                  id: bet.id,
                  amount: Decimal.to_string(bet.amount),
                  odds: Decimal.to_string(bet.odds),
                  status: bet.status,
                  team_picked: bet.team_picked,
                  potential_win: Decimal.to_string(bet.potential_win),
                  placed_at: bet.inserted_at,
                  game: %{
                    id: bet.game.id,
                    home_team: bet.game.home_team,
                    away_team: bet.game.away_team,
                    game_time: bet.game.game_time,
                    sport_type: bet.game.sport_type,
                    status: bet.game.status,
                    home_team_score: bet.game.home_team_score,
                    away_team_score: bet.game.away_team_score,
                    odds_home: Decimal.to_string(bet.game.odds_home),
                    odds_away: Decimal.to_string(bet.game.odds_away)
                  }
                }
              end)
            }

            json(conn, %{user: user_data})
        end

      :error ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "Invalid user ID format"})
    end
  end

  def delete_user(conn, %{"id" => user_id}) do
    case Accounts.soft_delete_user(user_id) do
      {:ok, _user} ->
        json(conn, %{message: "User deleted successfully"})

      {:error, _changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Failed to delete user"})
    end
  end

  def toggle_admin(conn, %{"id" => user_id}) do
    current_user = conn.assigns.current_user

    if Accounts.is_superuser?(current_user) do
      user = Accounts.get_user!(user_id)

      result =
        case user.is_admin do
          true -> Accounts.revoke_admin_access(current_user, user_id)
          false -> Accounts.grant_admin_access(current_user, user_id)
        end

      case result do
        {:ok, updated_user} ->
          json(conn, %{
            message: "Admin status updated",
            is_admin: updated_user.is_admin
          })

        {:error, _} ->
          conn
          |> put_status(:unprocessable_entity)
          |> json(%{error: "Failed to update admin status"})
      end
    else
      conn
      |> put_status(:forbidden)
      |> json(%{error: "Unauthorized action"})
    end
  end

  def profits(conn, _params) do
    profits = Accounts.calculate_profits()
            |> Enum.map(fn profit ->
              %{profit | total_profit: Decimal.to_string(profit.total_profit)}
            end)
    json(conn, %{profits: profits})
  end

  def create_game(conn, game_params) do
    case Betting.create_game(game_params) do
      {:ok, game} ->
        game_data = %{
          id: game.id,
          home_team: game.home_team,
          away_team: game.away_team,
          game_time: game.game_time,
          sport_type: game.sport_type,
          status: game.status,
          home_team_score: game.home_team_score,
          away_team_score: game.away_team_score,
          odds_home: Decimal.to_string(game.odds_home),
          odds_away: Decimal.to_string(game.odds_away),
          inserted_at: game.inserted_at,
          updated_at: game.updated_at
        }

        conn
        |> put_status(:created)
        |> json(%{game: game_data})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: format_changeset_errors(changeset)})
    end
  end

  def update_game(conn, %{"id" => game_id} = game_params) do
    game = Betting.get_game!(game_id)

    case Betting.update_game(game, game_params) do
      {:ok, updated_game} ->
        game_data = %{
          id: updated_game.id,
          home_team: updated_game.home_team,
          away_team: updated_game.away_team,
          game_time: updated_game.game_time,
          sport_type: updated_game.sport_type,
          status: updated_game.status,
          home_team_score: updated_game.home_team_score,
          away_team_score: updated_game.away_team_score,
          odds_home: Decimal.to_string(updated_game.odds_home),
          odds_away: Decimal.to_string(updated_game.odds_away),
          inserted_at: updated_game.inserted_at,
          updated_at: updated_game.updated_at
        }
        json(conn, %{game: game_data})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: format_changeset_errors(changeset)})
    end
  end

  # Helper function to format changeset errors
  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end

  @doc """
  Registers a new admin user. Only accessible by superusers.

  ## Parameters
    - conn: Connection struct
    - user_params: User registration parameters including role

  ## Returns
    - JSON response with created admin user data or errors
  """
  def register_admin(conn, %{"user" => user_params}) do
    current_user = conn.assigns.current_user

    case Accounts.register_admin(user_params, current_user) do
      {:ok, user} ->
        conn
        |> put_status(:created)
        |> json(%{
          data: %{
            id: user.id,
            email: user.email,
            role: user.role,
            created_at: user.inserted_at
          }
        })

      {:error, :unauthorized} ->
        conn
        |> put_status(:forbidden)
        |> json(%{error: "Only superusers can create admin accounts"})

      {:error, :invalid_role} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Invalid role specified"})

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: format_changeset_errors(changeset)})
    end
  end

  @doc """
  Soft deletes a user by setting their deleted_at timestamp.
  Only accessible by admin and superuser roles.

  ## Parameters
    - conn: Connection struct
    - %{"id" => user_id}: User ID to delete

  ## Returns
    - JSON response with success message or error
  """
  def soft_delete_user(conn, %{"id" => user_id}) do
    case Accounts.soft_delete_user(user_id) do
      {:ok, _user} ->
        conn
        |> put_status(:ok)
        |> json(%{
          data: %{
            message: "User successfully deleted",
            user_id: user_id
          }
        })

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "User not found"})

      {:error, _changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Failed to delete user"})
    end
  end
end
