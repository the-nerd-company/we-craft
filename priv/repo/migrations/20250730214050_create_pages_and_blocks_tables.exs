defmodule WeCraft.Repo.Migrations.CreatePagesAndBlocksTables do
  @moduledoc """
  Migration to create the pages and blocks tables.
  This migration sets up the necessary tables for managing pages and their block-based content structure within the WeCraft application.
  """
  use Ecto.Migration

  def change do
    create table(:pages) do
      add :title, :string, null: false
      add :slug, :string, null: false
      add :blocks, :map
      add :parent_page_id, :integer
      add :project_id, references(:projects, on_delete: :delete_all), null: false
      add :parent_id, references(:pages, on_delete: :delete_all)

      timestamps()
    end

    create unique_index(:pages, [:slug])
    create index(:pages, [:project_id])
    create index(:pages, [:parent_page_id])
    create index(:pages, [:parent_id])
  end
end
