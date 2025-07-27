defmodule WeCraft.Repo.Migrations.CreateCRMTables do
  @moduledoc """
  Migration to create CRM tables.
  """
  use Ecto.Migration

  def change do
    create table(:customers) do
      add :email, :string, null: false
      add :external_id, :string, null: false
      add :comment, :text
      add :name, :string, null: false
      add :metadata, :map
      add :tags, {:array, :string}
      add :project_id, references(:projects, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:customers, [:project_id, :external_id])
    create index(:customers, [:project_id])
  end
end
