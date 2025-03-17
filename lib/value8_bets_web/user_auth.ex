defmodule Value8BetsWeb.UserAuth do
  use Value8BetsWeb, :verified_routes

  import Plug.Conn, except: [assign: 3]
  import Phoenix.Controller
  import Phoenix.Component, only: [assign: 3]

  alias Value8Bets.Accounts
  alias Phoenix.LiveView

  # Make the remember me cookie valid for 60 days.
  # If you want to bump or reduce this value, also change
  # the token expiry itself in UserToken.
  @max_age 60 * 60 * 24 * 60
  @remember_me_cookie "_value8_bets_web_user_remember_me"
  @remember_me_options [sign: true, max_age: @max_age, same_site: "Lax"]

  @doc """
  Fetches the current user from the session or remember me cookie.

  ## Parameters
    - conn: The connection struct
    - _opts: Options (ignored)

  ## Returns
    - The connection struct with the current user assigned
  """
  def fetch_current_user(conn, _opts) do
    {user_token, conn} = ensure_user_token(conn)
    user = user_token && Accounts.get_user_by_session_token(user_token)
    Plug.Conn.assign(conn, :current_user, user)
  end

  @doc """
  Gets the user ID from the session token.

  ## Parameters
    - token: The session token

  ## Returns
    - The user ID or nil if the user is not found
  """
  def get_user_id_from_token(token) do
    case Accounts.get_user_by_session_token(token) do
      nil -> nil
      user -> user.id
    end
  end

  @doc """
  Ensures the user token is present in the session or remember me cookie.

  ## Parameters
    - conn: The connection struct

  ## Returns
    - A tuple with the user token and the updated connection struct
  """
  defp ensure_user_token(conn) do
    if token = get_session(conn, :user_token) do
      {token, conn}
    else
      conn = fetch_cookies(conn, signed: [@remember_me_cookie])

      if token = conn.cookies[@remember_me_cookie] do
        {token, put_token_in_session(conn, token)}
      else
        {nil, conn}
      end
    end
  end

  @doc """
  Puts the user token in the session.

  ## Parameters
    - conn: The connection struct
    - token: The user token

  ## Returns
    - The updated connection struct
  """
  defp put_token_in_session(conn, token) do
    conn
    |> put_session(:user_token, token)
    |> put_session(:live_socket_id, "users_sessions:#{Base.url_encode64(token)}")
  end

  @doc """
  Requires the user to be authenticated.

  If the user is not authenticated, redirects to the login page.

  ## Parameters
    - conn: The connection struct
    - _opts: Options (ignored)

  ## Returns
    - The connection struct or a redirect to the login page
  """
  def require_authenticated_user(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> put_flash(:error, "You must log in to access this page.")
      |> maybe_store_return_to()
      |> redirect(to: ~p"/users/log_in")
      |> halt()
    end
  end

  @doc """
  Stores the return to path in the session if the request method is GET.

  ## Parameters
    - conn: The connection struct

  ## Returns
    - The updated connection struct
  """
  defp maybe_store_return_to(%{method: "GET"} = conn) do
    %{request_path: request_path, query_string: query_string} = conn
    return_to = if query_string == "", do: request_path, else: request_path <> "?" <> query_string
    put_session(conn, :user_return_to, return_to)
  end

  defp maybe_store_return_to(conn), do: conn

  @doc """
  Logs in the user and sets the session and remember me cookie if applicable.

  ## Parameters
    - conn: The connection struct
    - user: The user struct
    - params: The parameters map (optional)

  ## Returns
    - The updated connection struct with the user logged in
  """
  def log_in_user(conn, user, params \\ %{}) do
    token = Accounts.generate_user_session_token(user)

    conn
    |> renew_session()
    |> put_session(:user_token, token)
    |> put_session(:live_socket_id, "users_sessions:#{Base.url_encode64(token)}")
    |> maybe_write_remember_me_cookie(token, params)
    |> put_flash(:info, "Welcome back!")
    |> redirect(to: ~p"/betting")
  end

  @doc """
  Writes the remember me cookie if the remember me option is set.

  ## Parameters
    - conn: The connection struct
    - token: The user token
    - params: The parameters map

  ## Returns
    - The updated connection struct
  """
  defp maybe_write_remember_me_cookie(conn, token, %{"remember_me" => "true"}) do
    put_resp_cookie(conn, @remember_me_cookie, token, @remember_me_options)
  end

  defp maybe_write_remember_me_cookie(conn, _token, _params) do
    conn
  end

  @doc """
  Renews the session by clearing and configuring it.

  ## Parameters
    - conn: The connection struct

  ## Returns
    - The updated connection struct
  """
  defp renew_session(conn) do
    conn
    |> configure_session(renew: true)
    |> clear_session()
  end

  @doc """
  Logs out the user and clears the session.

  ## Parameters
    - conn: The connection struct

  ## Returns
    - The updated connection struct with the user logged out
  """
  def log_out_user(conn) do
    if user_token = get_session(conn, :user_token) do
      Accounts.delete_user_session_token(user_token)
    end

    conn
    |> configure_session(drop: true)
    |> redirect(to: ~p"/")
  end

  @doc """
  Ensures the user is authenticated for LiveView.

  ## Parameters
    - _params: The parameters map (ignored)
    - session: The session map
    - socket: The LiveView socket

  ## Returns
    - The updated socket with the user assigned or a redirect to the login page
  """
  def on_mount(:ensure_authenticated, _params, session, socket) do
    if user_token = session["user_token"] do
      user = Accounts.get_user_by_session_token(user_token)

      if user do
        # Convert user to plain map with atom keys
        user_data = %{
          id: user.id,
          email: user.email,
          role: user.role,
          is_active: user.is_active
        }

        {:cont,
         socket
         |> assign(:current_user, user_data)
         |> assign(:user_token, user_token)}
      else
        {:halt,
         socket
         |> put_flash(:error, "You must log in to access this page.")
         |> redirect(to: ~p"/users/log_in")}
      end
    else
      {:halt,
       socket
       |> put_flash(:error, "You must log in to access this page.")
       |> redirect(to: ~p"/users/log_in")}
    end
  end

  @doc """
  Mounts the current user for LiveView.

  ## Parameters
    - _params: The parameters map (ignored)
    - session: The session map
    - socket: The LiveView socket

  ## Returns
    - The updated socket with the current user assigned
  """
  def on_mount(:mount_current_user, _params, session, socket) do
    case session["user_token"] do
      nil ->
        {:cont, assign(socket, :current_user, nil)}

      token ->
        if user = Accounts.get_user_by_session_token(token) do
          {:cont,
           socket
           |> assign(:current_user, user)
           |> assign(:user_token, token)}
        else
          {:cont, assign(socket, :current_user, nil)}
        end
    end
  end

  @doc """
  Used for routes that require admin access.

  ## Parameters
    - _params: The parameters map (ignored)
    - session: The session map
    - socket: The LiveView socket

  ## Returns
    - The updated socket with the current user assigned
  """
  def on_mount(:ensure_admin, _params, session, socket) do
    case session do
      %{"user_token" => user_token} ->
        user = Accounts.get_user_by_session_token(user_token)
        {:cont, assign(socket, :current_user, user)}

      _ ->
        {:cont, assign(socket, :current_user, nil)}
    end
  end

  @doc """
  Default mount for LiveView.

  ## Parameters
    - _params: The parameters map (ignored)
    - session: The session map
    - socket: The LiveView socket

  ## Returns
    - The updated socket with the current user assigned
  """
  def on_mount(:default, _params, session, socket) do
    if user_token = session["user_token"] do
      user = Accounts.get_user_by_session_token(user_token)

      if user do
        # Convert user to plain map to avoid serialization issues
        user_data = %{
          id: user.id,
          email: user.email,
          role: user.role,
          is_active: user.is_active
        }

        {:cont,
         socket
         |> assign(:current_user, user_data)
         |> assign(:user_token, user_token)}
      else
        {:cont, assign(socket, :current_user, nil)}
      end
    else
      {:cont, assign(socket, :current_user, nil)}
    end
  end
end
