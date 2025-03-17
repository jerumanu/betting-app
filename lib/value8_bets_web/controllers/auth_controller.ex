defmodule Value8BetsWeb.AuthController do
  use Value8BetsWeb, :controller
  alias Value8BetsWeb.Auth.Guardian

  @doc """
  Handles user login via API.

  Authenticates the user by email and password using the Guardian module.
  If successful, returns a JSON response with the user data and authentication token.
  Otherwise, returns a JSON error message.

  For malformed requests, returns a bad request error.

  ## Parameters
    - conn: The connection struct
    - params: The parameters map containing user credentials or invalid params

  ## Returns
    - JSON response with user data and authentication token or error message
  """
  def login(conn, %{"user" => %{"email" => email, "password" => password}}) do
    case Guardian.authenticate(email, password) do
      {:ok, {user, token}} ->
        conn
        |> put_status(:ok)
        |> json(%{
          data: %{
            id: user.id,
            email: user.email,
            role: user.role,
            token: token
          }
        })

      {:error, :unauthorized} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Invalid email or password"})
    end
  end

  def login(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Invalid request format"})
  end
end
