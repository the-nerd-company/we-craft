defmodule WeCraft.Chats.Infrastructure.ChatRepositoryEctoTest do
  @moduledoc """
  Test module for ChatRepositoryEcto
  """
  use WeCraft.DataCase, async: true

  alias WeCraft.Chats.ChatMember
  alias WeCraft.Chats.Infrastructure.ChatRepositoryEcto
  alias WeCraft.Repo

  import WeCraft.AccountsFixtures
  import WeCraft.ChatsFixtures

  describe "get_dm_chat/1" do
    test "returns DM chat between two specific users" do
      user1 = user_fixture()
      user2 = user_fixture()

      # Create a DM chat between user1 and user2
      dm_chat = dm_chat_fixture(%{user1: user1, user2: user2})

      # Test finding the chat from user1's perspective
      result = ChatRepositoryEcto.get_dm_chat(%{sender_id: user1.id, recipient_id: user2.id})

      assert result.id == dm_chat.id
      assert result.type == "dm"
      assert length(result.members) == 2

      member_user_ids = Enum.map(result.members, & &1.user.id)
      assert user1.id in member_user_ids
      assert user2.id in member_user_ids
    end

    test "returns same DM chat regardless of sender/recipient order" do
      user1 = user_fixture()
      user2 = user_fixture()

      # Create a DM chat between user1 and user2
      dm_chat = dm_chat_fixture(%{user1: user1, user2: user2})

      # Test both directions
      result1 = ChatRepositoryEcto.get_dm_chat(%{sender_id: user1.id, recipient_id: user2.id})
      result2 = ChatRepositoryEcto.get_dm_chat(%{sender_id: user2.id, recipient_id: user1.id})

      assert result1.id == dm_chat.id
      assert result2.id == dm_chat.id
      assert result1.id == result2.id
    end

    test "returns nil when no DM chat exists between users" do
      user1 = user_fixture()
      user2 = user_fixture()

      # Don't create any chat between them
      result = ChatRepositoryEcto.get_dm_chat(%{sender_id: user1.id, recipient_id: user2.id})

      assert result == nil
    end

    test "returns nil when chat has more than 2 members" do
      user1 = user_fixture()
      user2 = user_fixture()
      user3 = user_fixture()

      # Create a DM chat and manually add a third member
      dm_chat = dm_chat_fixture(%{user1: user1, user2: user2})

      {:ok, _member3} =
        %ChatMember{}
        |> ChatMember.changeset(%{
          user_id: user3.id,
          chat_id: dm_chat.id,
          joined_at: DateTime.utc_now()
        })
        |> Repo.insert()

      # Should not return this chat as it has 3 members, not 2
      result = ChatRepositoryEcto.get_dm_chat(%{sender_id: user1.id, recipient_id: user2.id})

      assert result == nil
    end

    test "ignores non-DM chats" do
      user1 = user_fixture()
      user2 = user_fixture()

      # Create a regular project chat (not DM) with these users
      project_chat = chat_fixture(%{type: "channel"})

      {:ok, _member1} =
        %ChatMember{}
        |> ChatMember.changeset(%{
          user_id: user1.id,
          chat_id: project_chat.id,
          joined_at: DateTime.utc_now()
        })
        |> Repo.insert()

      {:ok, _member2} =
        %ChatMember{}
        |> ChatMember.changeset(%{
          user_id: user2.id,
          chat_id: project_chat.id,
          joined_at: DateTime.utc_now()
        })
        |> Repo.insert()

      # Should not return the project chat, only DM chats
      result = ChatRepositoryEcto.get_dm_chat(%{sender_id: user1.id, recipient_id: user2.id})

      assert result == nil
    end

    test "preloads messages and member users correctly" do
      user1 = user_fixture()
      user2 = user_fixture()

      # Create a DM chat with a message
      dm_chat = dm_chat_fixture(%{user1: user1, user2: user2})

      _message =
        message_fixture(%{
          chat_id: dm_chat.id,
          sender_id: user1.id,
          content: "Hello!"
        })

      result = ChatRepositoryEcto.get_dm_chat(%{sender_id: user1.id, recipient_id: user2.id})

      # Check that associations are preloaded
      assert Ecto.assoc_loaded?(result.messages)
      assert Ecto.assoc_loaded?(result.members)
      assert length(result.messages) == 1
      assert length(result.members) == 2

      # Check that member users are preloaded
      for member <- result.members do
        assert Ecto.assoc_loaded?(member.user)
        assert member.user.id in [user1.id, user2.id]
      end
    end

    test "handles case where users have multiple DM chats (edge case)" do
      user1 = user_fixture()
      user2 = user_fixture()

      # This shouldn't happen in normal usage, but test robustness
      # Create first DM chat
      dm_chat1 = dm_chat_fixture(%{user1: user1, user2: user2})

      # Create second DM chat (this should be prevented by business logic, but test data layer)
      dm_chat2 = dm_chat_fixture(%{user1: user1, user2: user2})

      result = ChatRepositoryEcto.get_dm_chat(%{sender_id: user1.id, recipient_id: user2.id})

      # Should return one of the chats (the query will return one result)
      assert result != nil
      assert result.id in [dm_chat1.id, dm_chat2.id]
      assert result.type == "dm"
      assert length(result.members) == 2
    end
  end
end
