defmodule Value8Bets.Repo.Migrations.CreateBets do
  use Ecto.Migration

  def change do
    create table(:bets) do
      add :amount, :decimal, null: false
      add :odds, :decimal, null: false
      add :status, :string, default: "pending"
      add :team_picked, :string, null: false
      add :potential_win, :decimal, null: false
      add :user_id, references(:user_accounts, on_delete: :nothing), null: false
      add :game_id, references(:games, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:bets, [:user_id])
    create index(:bets, [:game_id])
    create index(:bets, [:status])
  end
end
