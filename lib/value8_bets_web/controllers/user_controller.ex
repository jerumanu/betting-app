defmodule Value8BetsWeb.UserController do
  use Value8BetsWeb, :controller
  alias Value8Bets.Accounts
  alias Value8BetsWeb.Auth.Guardian

  @doc """
  Shows the current user's details along with their bet history.

  If the user is authenticated, returns their details and bet history.
  Otherwise, returns an unauthorized error.

  ## Parameters
    - conn: The connection struct
    - _params: The parameters map (ignored)

  ## Returns
    - JSON response with user details and bet history or error message
  """
  def show(conn, _params) do
    case conn.assigns[:current_user] do
      nil ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Not authenticated"})

      user ->
        user_with_bets = Accounts.get_user_with_bet_history(user.id)

        json(conn, %{
          data: %{
            id: user.id,
            email: user.email,
            bets:
              Enum.map(user_with_bets.bets, fn bet ->
                %{
                  id: bet.id,
                  amount: bet.amount,
                  status: bet.status,
                  team_picked: bet.team_picked,
                  game: %{
                    home_team: bet.game.home_team,
                    away_team: bet.game.away_team
                  }
                }
              end)
          }
        })
    end
  end

  @doc """
  Lists all users with their statistics.

  Returns a JSON response with the list of users and their statistics.

  ## Parameters
    - conn: The connection struct
    - _params: The parameters map (ignored)

  ## Returns
    - JSON response with the list of users and their statistics
  """
  def index(conn, _params) do
    users = Accounts.list_users_with_stats()
    json(conn, %{data: users})
  end

  @doc """
  Lists all active users.

  Returns a JSON response with the list of active users.

  ## Parameters
    - conn: The connection struct
    - _params: The parameters map (ignored)

  ## Returns
    - JSON response with the list of active users
  """
  def active(conn, _params) do
    users = Accounts.list_active_users()
    json(conn, %{data: users})
  end

  @doc """
  Gets the current user's details.

  If the user is authenticated, returns their details.
  Otherwise, returns an unauthorized error.

  ## Parameters
    - conn: The connection struct
    - _params: The parameters map (ignored)

  ## Returns
    - JSON response with user details or error message
  """
  def get_user(conn, _params) do
    case Guardian.get_current_user(conn) do
      {:ok, user_data} ->
        conn
        |> put_status(:ok)
        |> json(%{data: user_data})

      {:error, :not_found} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "User not found"})
    end
  end
end
