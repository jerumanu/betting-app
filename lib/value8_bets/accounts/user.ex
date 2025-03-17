defmodule Value8Bets.Accounts.User do
  @moduledoc """
  User schema and related functions for authentication and authorization.
  
  This module handles:
  - User registration and validation
  - Password hashing and verification
  - Role management (user, admin, superuser)
  - Soft deletion functionality
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @hash_algorithm :sha256
  @rand_size 32
  @roles ["user", "admin", "superuser"]

  schema "user_accounts" do
    field :email, :string
    field :password, :string, virtual: true, redact: true  # Virtual field, not stored in DB
    field :password_hash, :string, redact: true
    field :confirmed_at, :naive_datetime
    field :role, :string, default: "user"
    field :is_active, :boolean, default: true
    field :deleted_at, :naive_datetime  # For soft delete functionality

    has_many :bets, Value8Bets.Betting.Bet
    has_many :user_tokens, Value8Bets.Accounts.UserToken

    timestamps()
  end

  @doc """
  Creates a changeset for user registration.
  
  ## Parameters
    - user: The user struct to change
    - attrs: The attributes to apply
    - opts: Optional parameters (currently unused)
    
  ## Returns
    - A changeset with validations for email and password
  """
  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :password, :role])
    |> validate_email()
    |> validate_password()
    |> validate_role()
  end

  @doc """
  Validates the email format and uniqueness.
  """
  defp validate_email(changeset) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> unsafe_validate_unique(:email, Value8Bets.Repo)
    |> unique_constraint(:email)
  end

  defp validate_password(changeset) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 6, max: 72)
    |> prepare_changes(&hash_password/1)
  end

  defp hash_password(changeset) do
    password = get_change(changeset, :password)

    changeset
    |> put_change(:password_hash, Bcrypt.hash_pwd_salt(password))
    |> delete_change(:password)
  end

  def valid_password?(%Value8Bets.Accounts.User{password_hash: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Bcrypt.no_user_verify()
    false
  end

  # Token-related functions
  def build_session_token(user) do
    token = :crypto.strong_rand_bytes(@rand_size)
    encoded_token = Base.url_encode64(token, padding: false)

    changeset =
      user
      |> change()
      |> put_change(:token, token)
      |> put_change(:token_context, "session")
      |> put_change(:token_inserted_at, NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second))

    {encoded_token, changeset}
  end

  def verify_session_token_query(token) do
    query =
      from u in __MODULE__,
        where: u.token == ^token and u.token_context == "session",
        where: u.token_inserted_at > ago(60, "day")

    {:ok, query}
  end

  def token_and_context_query(token, context) do
    from u in __MODULE__,
      where: u.token == ^token and u.token_context == ^context
  end

  def role_changeset(user, attrs) do
    user
    |> cast(attrs, [:role])
    |> validate_required([:role])
    |> validate_inclusion(:role, @roles)
  end

  def is_admin?(user), do: user.role in ["admin", "superuser"]
  def is_superuser?(user), do: user.role == "superuser"

  defp validate_role(changeset) do
    changeset
    |> validate_required([:role])
    |> validate_inclusion(:role, @roles)
  end
end
