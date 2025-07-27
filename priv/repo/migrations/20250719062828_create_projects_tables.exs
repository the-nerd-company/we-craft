defmodule WeCraft.Repo.Migrations.CreateProjectsTables do
  @moduledoc """
  Migration to create the projects tables.
  This migration sets up the necessary tables and relationships for managing projects within the WeCraft application.
  """
  use Ecto.Migration

  def change do
    create table(:projects) do
      add :title, :string
      add :description, :text
      add :repository_url, :string
      add :status, :string, null: false
      add :tags, {:array, :string}, default: []
      add :needs, {:array, :string}, default: []
      # Added business_domains field
      add :business_domains, {:array, :string}, default: []
      # Replacing existing status
      add :visibility, :string, null: false
      add :owner_id, references(:users, on_delete: :nilify_all)

      timestamps()
    end

    create table(:project_events) do
      add :event_type, :string, null: false
      add :metadata, :map, default: %{}
      add :project_id, references(:projects, on_delete: :delete_all)

      timestamps()
    end

    create table(:followers) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :project_id, references(:projects, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:followers, [:user_id])
    create index(:followers, [:project_id])
    create unique_index(:followers, [:user_id, :project_id])
  end
end
