defmodule WeCraft.Repo.Migrations.CreateTicketTables do
  @moduledoc """
  Represents a ticket in the system.
  """
  use Ecto.Migration

  def change do
    create table(:tickets) do
      add :title, :string, null: false
      add :type, :string, null: false
      add :description, :text
      add :status, :string, null: false
      add :priority, :integer, null: false
      add :project_id, references(:projects, on_delete: :delete_all), null: false
      add :customer_id, references(:customers, on_delete: :nilify_all)
      timestamps()
    end

    create index(:tickets, [:project_id])
  end
end
