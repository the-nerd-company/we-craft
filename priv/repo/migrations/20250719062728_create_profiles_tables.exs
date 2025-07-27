defmodule WeCraft.Repo.Migrations.CreateProfilesTables do
  @moduledoc """
  Migration to create the profiles table in the WeCraft application.
  """
  use Ecto.Migration

  def change do
    create table(:profiles) do
      add :bio, :text
      add :offers, {:array, :string}, default: []
      add :skills, {:array, :string}, default: []
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:profiles, [:user_id])
  end
end
