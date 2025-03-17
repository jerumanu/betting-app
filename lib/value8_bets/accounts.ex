defmodule Value8Bets.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Value8Bets.Repo
  alias Value8Bets.Accounts.{User, UserToken}
  alias Value8Bets.Betting.{Bet, Game}

  def get_user_by_session_token(token) when is_binary(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Registers a new user with specified role.
  """
  def register_user(attrs) do
    # Allow the role to be set from params, default to "user"
    attrs = 
      attrs
      |> Map.new(fn {k, v} -> {to_string(k), v} end)
      |> Map.put_new("role", "user") # Only set role if not provided

    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Registers an admin user. Only callable by superusers.
  """
  def register_admin(attrs, current_user) do
    if current_user && current_user.role == "superuser" do
      role = attrs["role"] || "admin"
      
      if role in ["admin", "superuser"] do
        attrs = 
          attrs
          |> Map.new(fn {k, v} -> {to_string(k), v} end)
          |> Map.put("role", role)

        %User{}
        |> User.registration_changeset(attrs)
        |> Repo.insert()
      else
        {:error, :invalid_role}
      end
    else
      {:error, :unauthorized}
    end
  end

  def get_user!(id), do: Repo.get!(User, id)

  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = get_user_by_email(email)
    if User.valid_password?(user, password), do: user
  end

  def change_user_registration(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs)
  end

  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  # def get_user_with_bet_history(user_id) do
  #   Repo.get(User, user_id)
  #   |> Repo.preload(:bets)
  # end

  def delete_user_session_token(token) do
    Repo.delete_all(UserToken.token_and_context_query(token, "session"))
    :ok
  end

  @doc """
  Lists all users with their betting statistics and roles.
  """
  def list_users_with_stats do
    from(u in User,
      left_join: b in assoc(u, :bets),
      group_by: [u.id, u.email, u.role, u.is_active, u.inserted_at],
      select: %{
        id: u.id,
        email: u.email,
        role: u.role,
        is_active: u.is_active,
        total_bets: count(b.id),
        total_amount_bet: sum(b.amount),
        total_winnings: sum(
          fragment(
            "CASE WHEN ? = 'won' THEN ? * ? ELSE 0 END",
            b.status,
            b.amount,
            b.odds
          )
        ),
        inserted_at: u.inserted_at
      }
    )
    |> Repo.all()
  end

  @doc """
  Gets active users who placed bets in the last 7 days.
  """
  def list_active_users do
    seven_days_ago = DateTime.utc_now() |> DateTime.add(-7 * 24 * 60 * 60)

    from(u in User,
      join: b in assoc(u, :bets),
      where: b.inserted_at >= ^seven_days_ago,
      group_by: [u.id, u.email],
      select: %{
        id: u.id,
        email: u.email,
        last_bet_at: max(b.inserted_at),
        bets_last_7_days: count(b.id)
      },
      order_by: [desc: max(b.inserted_at)]
    )
    |> Repo.all()
  end

  @doc """
  Gets a user by ID.
  Returns nil if the user does not exist.
  """
  def get_user(id) do
    User
    |> where([u], is_nil(u.deleted_at))
    |> Repo.get(id)
  end

  @doc """
  Gets a user by ID with preloaded bets.
  Returns nil if the user does not exist.
  """
  def get_user_with_bets(id) when is_integer(id) do
    User
    |> where(id: ^id)
    |> preload(:bets)
    |> Repo.one()
  end

  @doc """
  Gets a user by ID with their active bets.
  Returns nil if the user does not exist.
  """
  def get_user_with_active_bets(id) when is_integer(id) do
    pending_bets_query = from(b in Value8Bets.Betting.Bet, where: b.status == "pending")

    User
    |> where(id: ^id)
    |> preload(bets: ^pending_bets_query)
    |> Repo.one()
  end


  @doc """
  Gets a user by ID with their bet history.
  Includes bet details and associated games.


  """
  def get_user_with_bet_history(id) when is_integer(id) do
    bets_query = from(b in Value8Bets.Betting.Bet,
      order_by: [desc: b.inserted_at],
      preload: [:game]
    )

    User
    |> where(id: ^id)
    |> preload(bets: ^bets_query)
    |> Repo.one()
  end

  @doc """
  Fetches the current user by token or ID.

  ## Examples

      iex> fetch_current_user(token)
      %User{}

      iex> fetch_current_user(user_id)
      %User{}

      iex> fetch_current_user(nil)
      nil
  """
  def fetch_current_user(nil), do: nil

  def fetch_current_user(token) when is_binary(token) do
    case get_user_by_session_token(token) do
      nil -> nil
      user ->
        user
        |> Repo.preload(bets: from(b in Value8Bets.Betting.Bet,
          order_by: [desc: b.inserted_at],
          preload: [:game]
        ))
    end
  end

  # Admin Functions
  def list_users_with_bets do
    User
    |> where([u], is_nil(u.deleted_at))
    |> preload(bets: [:game])
    |> Repo.all()
  end

  def get_user_with_bets!(id) do
    User
    |> where([u], u.id == ^id and is_nil(u.deleted_at))
    |> preload(bets: [:game])
    |> Repo.one!()
  end

  @doc """
  Soft deletes a user by setting their deleted_at timestamp.

  ## Parameters
    - id: The user ID to soft delete

  ## Returns
    - {:ok, user} on success
    - {:error, :not_found} if user doesn't exist
    - {:error, changeset} on validation failure
  """
  def soft_delete_user(id) do
    case get_user(id) do
      nil -> 
        {:error, :not_found}
      user -> 
        user
        |> Ecto.Changeset.change(%{
          deleted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
          is_active: false
        })
        |> Repo.update()
    end
  end

  def calculate_profits do
    from(b in Bet,
      join: u in assoc(b, :user),
      where: b.status == "lost" and is_nil(u.deleted_at),
      group_by: [b.game_id],
      select: %{
        game_id: b.game_id,
        total_profit: sum(b.amount)
      }
    )
    |> Repo.all()
  end

  # Superuser Functions
  def grant_admin_access(granter, user_id) do
    if is_superuser?(granter) do
      user = get_user!(user_id)
      
      user
      |> User.role_changeset(%{role: "admin"})
      |> Repo.update()
    else
      {:error, :unauthorized}
    end
  end

  def revoke_admin_access(revoker, user_id) do
    if is_superuser?(revoker) do
      user = get_user!(user_id)
      
      user
      |> User.role_changeset(%{role: "user"})
      |> Repo.update()
    else
      {:error, :unauthorized}
    end
  end

  def is_admin?(nil), do: false
  def is_admin?(%User{} = user), do: User.is_admin?(user)

  def is_superuser?(nil), do: false
  def is_superuser?(%User{} = user), do: User.is_superuser?(user)

  @doc """
  Updates a user's role.
  """
  def update_user_role(current_user, user_id, new_role) do
    if is_authorized_for_role_change?(current_user, new_role) do
      user = get_user!(user_id)
      
      user
      |> User.role_changeset(%{role: new_role})
      |> Repo.update()
    else
      {:error, :unauthorized}
    end
  end

  @doc """
  Checks if a user is authorized to perform admin actions.
  """
  def is_admin?(user), do: User.is_admin?(user)

  @doc """
  Checks if a user is a superuser.
  """
  def is_superuser?(user), do: User.is_superuser?(user)

  defp is_authorized_for_role_change?(current_user, new_role) do
    cond do
      is_superuser?(current_user) -> true
      is_admin?(current_user) and new_role == "user" -> true
      true -> false
    end
  end

  @doc """
  Lists all admin users.
  """
  def list_admins do
    User
    |> where([u], u.role in ["admin", "superuser"])
    |> where([u], is_nil(u.deleted_at))
    |> Repo.all()
  end
end
