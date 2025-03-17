defmodule Value8Bets.Betting.Bet do
  use Ecto.Schema
  import Ecto.Changeset

  schema "bets" do
    field :amount, :decimal
    field :odds, :decimal
    field :status, :string, default: "pending" # pending, won, lost, cancelled
    field :team_picked, :string
    field :potential_win, :decimal
    
    belongs_to :user, Value8Bets.Accounts.User, foreign_key: :user_id
    belongs_to :game, Value8Bets.Betting.Game

    timestamps()
  end

  def changeset(bet, attrs) do
    bet
    |> cast(attrs, [:amount, :odds, :status, :team_picked, :potential_win, :user_id, :game_id])
    |> validate_required([:amount, :odds, :team_picked, :user_id, :game_id])
    |> validate_number(:amount, greater_than: 0)
    |> validate_number(:odds, greater_than: 1)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:game_id)
    |> calculate_potential_win()
  end

  defp calculate_potential_win(changeset) do
    case {get_field(changeset, :amount), get_field(changeset, :odds)} do
      {amount, odds} when not is_nil(amount) and not is_nil(odds) ->
        potential_win = Decimal.mult(amount, odds)
        put_change(changeset, :potential_win, potential_win)
      _ ->
        changeset
    end
  end
end 