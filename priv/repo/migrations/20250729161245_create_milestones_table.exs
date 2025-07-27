defmodule WeCraft.Repo.Migrations.CreateMilestonesTable do
  @moduledoc """
  Migration to create the milestones table.
  This migration sets up the necessary table for managing project milestones within the WeCraft application.
  """
  use Ecto.Migration

  def change do
    create table(:milestones) do
      add :title, :string, null: false
      add :description, :text, null: false
      add :due_date, :utc_datetime
      add :completed_at, :utc_datetime
      add :status, :string, null: false
      add :project_id, references(:projects, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:milestones, [:project_id])

    create table(:tasks) do
      add :title, :string, null: false
      add :description, :text, null: false
      add :status, :string, null: false
      add :milestone_id, references(:milestones, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:tasks, [:milestone_id])
  end
end
