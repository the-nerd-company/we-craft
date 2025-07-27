defmodule WeCraft.Chats.Chat do
  @moduledoc """
  Represents a chat associated with a project in the WeCraft application.
  """

  use Ecto.Schema

  import Ecto.Changeset
  alias WeCraft.Chats.{ChatMember, Message}
  alias WeCraft.Projects.Project

  schema "chats" do
    field :name, :string
    field :description, :string
    field :is_main, :boolean
    field :is_public, :boolean
    field :room_uuid, Ecto.UUID
    field :type, :string
    belongs_to :project, Project
    has_many :messages, Message
    has_many :members, ChatMember

    timestamps()
  end

  @doc false
  def changeset(chat, attrs) do
    chat
    |> cast(attrs, [:name, :description, :is_main, :is_public, :room_uuid, :type, :project_id])
    |> validate_required([:is_main, :is_public, :room_uuid, :type])
  end
end
