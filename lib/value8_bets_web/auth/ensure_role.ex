defmodule Value8BetsWeb.Auth.EnsureRole do
  @moduledoc """
  Plug to ensure a user has the required role to access a route.
  """

  import Plug.Conn
  import Phoenix.Controller
  alias Value8BetsWeb.Auth.Guardian
  alias Value8Bets.Accounts.User

  def init(opts), do: opts

  @doc """
  Checks if the current user has the required role.
  """
  def call(conn, required_role) do
    current_user = Guardian.Plug.current_resource(conn)

    if authorize_role?(current_user, required_role) do
      conn
    else
      conn
      |> put_status(:forbidden)
      |> Phoenix.Controller.json(%{error: "Unauthorized"})
      |> halt()
    end
  end

  defp authorize_role?(user, required_role) do
    case required_role do
      "admin" -> User.is_admin?(user)
      "superuser" -> User.is_superuser?(user)
      _ -> true
    end
  end
end 