defmodule Value8Bets.Repo.Migrations.CreateUserAccounts do
  use Ecto.Migration

  def change do
    create table(:user_accounts) do
      add :email, :string, null: false
      add :password_hash, :string, null: false
      add :confirmed_at, :naive_datetime
      add :deleted_at, :naive_datetime

      timestamps()
    end

    create unique_index(:user_accounts, [:email])
  end
end 