defmodule Value8BetsWeb.UserSessionController do
  use Value8BetsWeb, :controller

  alias Value8Bets.Accounts
  alias Value8BetsWeb.UserAuth

  @doc """
  Renders the login form.

  If a `return_to` parameter is provided, it stores the path in the session.
  """
  def new(conn, params) do
    # Store the return_to path from query params in the session
    conn =
      if return_to = params["return_to"] do
        put_session(conn, :user_return_to, return_to)
      else
        conn
      end

    render(conn, :new, error_message: nil)
  end

  @doc """
  Handles user login.

  Authenticates the user by email and password. If successful, stores the user token in the session and redirects to the betting page. Otherwise, renders the login form with an error message.
  """
  def create(conn, %{"user" => user_params}) do
    %{"email" => email, "password" => password} = user_params

    if user = Accounts.get_user_by_email_and_password(email, password) do
      token = Accounts.generate_user_session_token(user)

      conn
      |> put_session(:user_token, token)
      |> put_session(:live_socket_id, "users_sessions:#{Base.url_encode64(token)}")
      |> put_flash(:info, "Welcome back!")
      |> redirect(to: ~p"/betting")
    else
      render(conn, :new, error_message: "Invalid email or password")
    end
  end

  @doc """
  Handles user logout.

  Logs out the user, clears the session, and redirects to the home page with a flash message.
  """
  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserAuth.log_out_user()
    |> redirect(to: ~p"/")
  end

  @doc """
  Provides API instructions for logging in.

  Returns a JSON message instructing the user to use the POST /api/users/login endpoint with email and password.
  """
  def new_api(conn, _params) do
    json(conn, %{
      data: %{
        message: "Use POST /api/users/login with email and password to login"
      }
    })
  end

  @doc """
  Handles API user login.

  Authenticates the user by email and password. If successful, returns a JSON response with the user ID, email, and token. Otherwise, returns a JSON error message.
  """
  def create_api(conn, %{"user" => %{"email" => email, "password" => password}}) do
    if user = Accounts.get_user_by_email_and_password(email, password) do
      token = Accounts.generate_user_session_token(user)

      conn
      |> put_session(:user_token, token)
      |> json(%{
        data: %{
          id: user.id,
          email: user.email,
          token: token
        }
      })
    else
      conn
      |> put_status(:unauthorized)
      |> json(%{error: "Invalid email or password"})
    end
  end
end
