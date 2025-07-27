defmodule WeCraft.Chats.Message do
  @moduledoc """
  Represents a message in the chat system with rich content support.
  Supports Slack-like rich formatting including mentions, links, blocks, etc.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias WeCraft.Accounts.User

  alias WeCraft.Chats.{
    Chat,
    RichTextProcessor
  }

  @message_types ~w[text system thread_reply file image]

  schema "messages" do
    field :content, :string
    field :timestamp, :utc_datetime

    # Rich content fields
    field :blocks, {:array, :map}, default: []
    field :mentions, {:array, :map}, default: []
    field :links, {:array, :map}, default: []
    field :message_type, :string, default: "text"
    field :raw_content, :string
    field :html_content, :string

    # Thread support
    field :thread_ts, :string
    belongs_to :parent_message, __MODULE__

    # Reactions and metadata
    field :reactions, {:array, :map}, default: []
    field :metadata, :map, default: %{}

    belongs_to :sender, User
    belongs_to :chat, Chat

    timestamps()
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [
      :content,
      :sender_id,
      :chat_id,
      :timestamp,
      :blocks,
      :mentions,
      :links,
      :message_type,
      :raw_content,
      :html_content,
      :thread_ts,
      :parent_message_id,
      :reactions,
      :metadata
    ])
    |> validate_required([:content, :sender_id, :chat_id, :timestamp])
    |> validate_inclusion(:message_type, @message_types)
    |> validate_length(:content, max: 4000)
    |> validate_length(:raw_content, max: 4000)
    |> process_rich_content()
  end

  @doc """
  Process rich content from raw input and extract mentions, links, etc.
  """
  def process_rich_content(%Ecto.Changeset{valid?: true} = changeset) do
    content = get_change(changeset, :content) || get_field(changeset, :content)
    raw_content = get_change(changeset, :raw_content) || content

    if content do
      {blocks, mentions, links} = RichTextProcessor.process(content)

      changeset
      |> put_change(:raw_content, raw_content || content)
      |> put_change(:blocks, blocks)
      |> put_change(:mentions, mentions)
      |> put_change(:links, links)
    else
      changeset
    end
  end

  def process_rich_content(changeset), do: changeset

  @doc """
  Get all mentioned user IDs from the message
  """
  def mentioned_user_ids(%__MODULE__{mentions: mentions}) do
    mentions
    |> Enum.filter(&(&1["type"] == "user"))
    |> Enum.map(& &1["user_id"])
  end

  @doc """
  Check if message is in a thread
  """
  def in_thread?(%__MODULE__{parent_message_id: parent_id}), do: !is_nil(parent_id)
  def in_thread?(_), do: false

  @doc """
  Check if message has rich content
  """
  def has_rich_content?(%__MODULE__{blocks: blocks}) when length(blocks) > 0, do: true
  def has_rich_content?(%__MODULE__{mentions: mentions}) when length(mentions) > 0, do: true
  def has_rich_content?(%__MODULE__{links: links}) when length(links) > 0, do: true
  def has_rich_content?(_), do: false
end
