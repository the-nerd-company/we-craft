defmodule WeCraft.Repo.Migrations.CreateChatsTables do
  @moduledoc """
  Migration to create the chats and messages tables.
  """
  use Ecto.Migration

  def change do
    create table(:chats) do
      add :is_main, :boolean, null: false
      add :project_id, references(:projects, on_delete: :delete_all), null: true
      add :type, :string, null: false, default: "channel"
      add :is_public, :boolean, null: false
      add :name, :string
      add :description, :text

      timestamps()
    end

    create index(:chats, [:project_id])
    create constraint(:chats, :valid_type, check: "type IN ('dm', 'channel')")

    create table(:messages) do
      add :content, :text, null: false
      add :timestamp, :utc_datetime, null: false
      add :sender_id, references(:users, on_delete: :nothing), null: false
      add :chat_id, references(:chats, on_delete: :delete_all), null: false
      add :blocks, :jsonb, default: "[]"
      add :mentions, :jsonb, default: "[]"
      add :links, :jsonb, default: "[]"
      add :message_type, :string, default: "text"
      add :raw_content, :text
      add :html_content, :text
      add :thread_ts, :string
      add :parent_message_id, references(:messages, on_delete: :delete_all)
      add :reactions, :jsonb, default: "[]"
      add :metadata, :jsonb, default: "{}"

      timestamps()
    end

    create index(:messages, [:chat_id])
    create index(:messages, [:sender_id])
    create index(:messages, [:thread_ts])
    create index(:messages, [:parent_message_id])
    create index(:messages, [:message_type])

    # GIN indexes for JSON fields for fast querying
    create index(:messages, [:blocks], using: :gin)
    create index(:messages, [:mentions], using: :gin)
    create index(:messages, [:links], using: :gin)
    create index(:messages, [:reactions], using: :gin)

    # Create members table to track chat memberships
    create table(:chat_members) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :chat_id, references(:chats, on_delete: :delete_all), null: false
      add :joined_at, :utc_datetime, null: false

      timestamps()
    end

    # Ensure unique membership per user per chat
    create unique_index(:chat_members, [:user_id, :chat_id])
    create index(:chat_members, [:chat_id])
    create index(:chat_members, [:user_id])
  end
end
