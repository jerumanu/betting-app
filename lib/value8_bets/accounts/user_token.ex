defmodule Value8Bets.Accounts.UserToken do
  use Ecto.Schema
  import Ecto.Query

  @hash_algorithm :sha256
  @rand_size 32

  schema "user_tokens" do
    field :token, :binary
    field :context, :string
    belongs_to :user, Value8Bets.Accounts.User

    timestamps(updated_at: false)
  end

  def build_session_token(user) do
    token = :crypto.strong_rand_bytes(@rand_size)
    {Base.url_encode64(token, padding: false),
     %Value8Bets.Accounts.UserToken{
       token: token,
       context: "session",
       user_id: user.id
     }}
  end

  def verify_session_token_query(token) do
    query =
      from token in token_and_context_query(token, "session"),
        join: user in assoc(token, :user),
        where: token.inserted_at > ago(60, "day"),
        select: user

    {:ok, query}
  end

  def token_and_context_query(token, context) do
    from Value8Bets.Accounts.UserToken,
      where: [token: ^token, context: ^context]
  end
end 