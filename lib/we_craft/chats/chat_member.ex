defmodule WeCraft.Chats.ChatMember do
  @moduledoc """
  Represents a member of a chat in the WeCraft application.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "chat_members" do
    field :chat_id, :integer
    field :joined_at, :utc_datetime

    belongs_to :user, WeCraft.Accounts.User

    timestamps()
  end

  def changeset(chat_member, attrs) do
    chat_member
    |> cast(attrs, [:user_id, :chat_id, :joined_at])
    |> validate_required([:user_id, :chat_id, :joined_at])
  end
end
