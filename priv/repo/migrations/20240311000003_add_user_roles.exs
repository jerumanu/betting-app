defmodule Value8Bets.Repo.Migrations.AddUserRoles do
  use Ecto.Migration

  def change do
    alter table(:user_accounts) do
      add :role, :string, default: "user"
      add :is_active, :boolean, default: true
    end

    create index(:user_accounts, [:role])
  end
end 