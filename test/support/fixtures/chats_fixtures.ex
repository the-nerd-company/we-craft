defmodule WeCraft.ChatsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `WeCraft.Chats` context.
  """

  alias WeCraft.Chats
  alias WeCraft.Chats.{Chat, ChatMember, Message}
  alias WeCraft.Repo

  import WeCraft.AccountsFixtures
  import WeCraft.ProjectsFixtures

  @doc """
  Generate a chat.
  """
  def chat_fixture(attrs \\ %{}) do
    project = attrs[:project] || project_fixture()

    {:ok, chat} =
      attrs
      |> Enum.into(%{
        project_id: project.id,
        name: "General Chat",
        description: "General discussion",
        is_main: true,
        is_public: true,
        type: "channel"
      })
      |> then(&Chats.create_project_chat(%{attrs: &1}))

    chat
  end

  @doc """
  Generate a DM chat between two users.
  """
  def dm_chat_fixture(attrs \\ %{}) do
    user1 = attrs[:user1] || user_fixture()
    user2 = attrs[:user2] || user_fixture()

    # Create DM chat directly
    chat_attrs = %{
      is_main: false,
      is_public: false,
      room_uuid: Ecto.UUID.generate(),
      type: "dm"
    }

    {:ok, chat} =
      %Chat{}
      |> Chat.changeset(chat_attrs)
      |> Repo.insert()

    # Add members
    {:ok, _member1} =
      %ChatMember{}
      |> ChatMember.changeset(%{
        user_id: user1.id,
        chat_id: chat.id,
        joined_at: DateTime.utc_now()
      })
      |> Repo.insert()

    {:ok, _member2} =
      %ChatMember{}
      |> ChatMember.changeset(%{
        user_id: user2.id,
        chat_id: chat.id,
        joined_at: DateTime.utc_now()
      })
      |> Repo.insert()

    # Reload with preloads
    chat
    |> Repo.preload([:messages, members: [:user]])
  end

  @doc """
  Generate a message.
  """
  def message_fixture(attrs \\ %{}) do
    chat = attrs[:chat] || chat_fixture()
    sender = attrs[:sender] || user_fixture()

    default_attrs = %{
      chat_id: chat.id,
      sender_id: sender.id,
      content: "Test message content",
      timestamp: DateTime.utc_now(),
      blocks: [],
      mentions: [],
      links: [],
      reactions: [],
      message_type: "text"
    }

    message_attrs = Enum.into(attrs, default_attrs)

    # Create message directly in the database to avoid business logic constraints
    %Message{}
    |> Message.changeset(message_attrs)
    |> Repo.insert!()
    |> Repo.preload([:sender, :chat])
  end

  @doc """
  Generate a threaded message.
  """
  def threaded_message_fixture(attrs \\ %{}) do
    parent = attrs[:parent_message] || message_fixture()

    attrs
    |> Map.put(:parent_message_id, parent.id)
    |> Map.put(:thread_ts, parent.ts)
    |> message_fixture()
  end

  @doc """
  Generate a message with rich content blocks.
  """
  def rich_message_fixture(attrs \\ %{}) do
    blocks =
      attrs[:blocks] ||
        [
          %{
            "type" => "section",
            "text" => %{"type" => "mrkdwn", "text" => "Hello *world*!"}
          }
        ]

    attrs
    |> Map.put(:blocks, blocks)
    |> message_fixture()
  end

  @doc """
  Generate a message with mentions.
  """
  def message_with_mentions_fixture(attrs \\ %{}) do
    user = user_fixture()

    mentions =
      attrs[:mentions] ||
        [
          %{
            "type" => "user",
            "user_id" => user.id,
            "display_name" => user.email,
            "start" => 0,
            "length" => 10
          }
        ]

    attrs
    |> Map.put(:mentions, mentions)
    |> Map.put(:content, "@#{user.email} hello there")
    |> message_fixture()
  end

  @doc """
  Generate a message with reactions.
  """
  def message_with_reactions_fixture(attrs \\ %{}) do
    user1 = user_fixture()
    user2 = user_fixture()

    reactions =
      attrs[:reactions] ||
        [
          %{"emoji" => "👍", "users" => [user1.id, user2.id]},
          %{"emoji" => "❤️", "users" => [user1.id]}
        ]

    attrs
    |> Map.put(:reactions, reactions)
    |> message_fixture()
  end

  @doc """
  Generate a code message.
  """
  def code_message_fixture(attrs \\ %{}) do
    blocks = [
      %{
        "type" => "code",
        "text" => "const x = 1;\nconsole.log(x);"
      }
    ]

    attrs
    |> Map.put(:blocks, blocks)
    |> message_fixture()
  end

  @doc """
  Generate a quote message.
  """
  def quote_message_fixture(attrs \\ %{}) do
    blocks = [
      %{
        "type" => "quote",
        "text" => "This is a quoted message"
      }
    ]

    attrs
    |> Map.put(:blocks, blocks)
    |> message_fixture()
  end
end
