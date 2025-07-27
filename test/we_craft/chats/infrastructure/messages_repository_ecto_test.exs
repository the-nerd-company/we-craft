defmodule WeCraft.Chats.Infrastructure.MessagesRepositoryEctoTest do
  @moduledoc """
  Test module for MessagesRepositoryEcto
  """
  use WeCraft.DataCase, async: true

  alias WeCraft.Chats.Infrastructure.MessagesRepositoryEcto

  import WeCraft.AccountsFixtures
  import WeCraft.ChatsFixtures

  describe "create_message/1" do
    test "creates a message with valid attributes" do
      user = user_fixture()
      chat = chat_fixture()

      attrs = %{
        content: "Test message content",
        sender_id: user.id,
        chat_id: chat.id,
        timestamp: DateTime.utc_now()
      }

      assert {:ok, message} = MessagesRepositoryEcto.create_message(attrs)

      assert message.content == attrs.content
      assert message.sender_id == user.id
      assert message.chat_id == chat.id
      # Allow for small timestamp differences due to precision
      assert DateTime.diff(message.timestamp, attrs.timestamp, :microsecond) |> abs() < 1_000_000
      assert message.message_type == "text"
      # The rich text processor will generate blocks from any content
      assert is_list(message.blocks)
      # Basic attributes should be empty/default when not provided
      assert message.mentions == []
      assert message.links == []
      assert message.reactions == []
    end

    test "creates a message with rich content" do
      user = user_fixture()
      chat = chat_fixture()

      # Content with rich formatting that will be processed
      content = "Hello *world*!"

      attrs = %{
        content: content,
        sender_id: user.id,
        chat_id: chat.id,
        timestamp: DateTime.utc_now(),
        message_type: "text"
      }

      assert {:ok, message} = MessagesRepositoryEcto.create_message(attrs)

      assert message.content == attrs.content
      # The rich content processor will generate blocks from the content
      assert is_list(message.blocks)
      assert message.message_type == "text"
      # Raw content should be preserved
      assert message.raw_content == content
    end

    test "returns error with invalid attributes" do
      # Missing required fields
      attrs = %{content: "Test message"}

      assert {:error, changeset} = MessagesRepositoryEcto.create_message(attrs)
      assert changeset.errors[:sender_id]
      assert changeset.errors[:chat_id]
      assert changeset.errors[:timestamp]
    end

    test "returns error with empty content" do
      user = user_fixture()
      chat = chat_fixture()

      attrs = %{
        content: "",
        sender_id: user.id,
        chat_id: chat.id,
        timestamp: DateTime.utc_now()
      }

      assert {:error, changeset} = MessagesRepositoryEcto.create_message(attrs)
      assert changeset.errors[:content]
    end

    test "returns error with invalid message_type" do
      user = user_fixture()
      chat = chat_fixture()

      attrs = %{
        content: "Test message",
        sender_id: user.id,
        chat_id: chat.id,
        timestamp: DateTime.utc_now(),
        message_type: "invalid_type"
      }

      assert {:error, changeset} = MessagesRepositoryEcto.create_message(attrs)
      assert changeset.errors[:message_type]
    end

    test "returns error with content that is too long" do
      user = user_fixture()
      chat = chat_fixture()

      # Create content that exceeds the 4000 character limit
      long_content = String.duplicate("a", 4001)

      attrs = %{
        content: long_content,
        sender_id: user.id,
        chat_id: chat.id,
        timestamp: DateTime.utc_now()
      }

      assert {:error, changeset} = MessagesRepositoryEcto.create_message(attrs)
      assert changeset.errors[:content]
    end
  end
end
