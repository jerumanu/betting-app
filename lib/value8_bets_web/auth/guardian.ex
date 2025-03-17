defmodule Value8BetsWeb.Auth.Guardian do
  use Guardian, otp_app: :value8_bets

  alias Value8Bets.Accounts

  @doc """
  Authenticates a user with email and password.

  ## Parameters
    - email: The user's email
    - password: The user's password

  ## Returns
    - {:ok, {user, token}} if authentication succeeds
    - {:error, :unauthorized} if authentication fails
  """
  def authenticate(email, password) do
    case Accounts.get_user_by_email(email) do
      nil ->
        {:error, :unauthorized}

      user ->
        case validate_password(password, user.password_hash) do
          true -> 
            case encode_and_sign(user, %{role: user.role}, token_type: "access") do
              {:ok, token, _claims} -> {:ok, {user, token}}
              _error -> {:error, :unauthorized}
            end
          false -> 
            {:error, :unauthorized}
        end
    end
  end

  def subject_for_token(%{id: id}, _claims) do
    {:ok, to_string(id)}
  end

  def subject_for_token(_, _) do
    {:error, :no_id_provided}
  end

  def resource_from_claims(%{"sub" => id}) do
    case Accounts.get_user!(id) do
      nil -> {:error, :not_found}
      user -> {:ok, user}
    end
  end

  def resource_from_claims(_claims) do
    {:error, :no_id_provided}
  end

  def get_current_user(conn) do
    case Guardian.Plug.current_resource(conn) do
      nil -> {:error, :not_found}
      user -> 
        user_data = %{
          id: user.id,
          email: user.email,
          role: user.role,
          is_active: user.is_active
        }
        {:ok, user_data}
    end
  end

  def create_token(user) do
    {:ok, token, _claims} = encode_and_sign(user, %{
      role: get_role(user)
    })
    {:ok, token}
  end

  defp get_role(user) do
    user.role
  end

  defp validate_password(password, stored_hash) do
    Bcrypt.verify_pass(password, stored_hash)
  end
end 