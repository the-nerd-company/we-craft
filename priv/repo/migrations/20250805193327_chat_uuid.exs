defmodule WeCraft.Repo.Migrations.ChatUuid do
  @moduledoc """
  Adds a UUID column to the chats table.
  """
  use Ecto.Migration

  def change do
    alter table(:chats) do
      add :room_uuid, :uuid, null: false, default: fragment("gen_random_uuid()")
    end
  end
end
