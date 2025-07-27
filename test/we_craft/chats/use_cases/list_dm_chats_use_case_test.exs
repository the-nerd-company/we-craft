defmodule WeCraft.Chats.UseCases.ListDmUseCaseTest do
  @moduledoc """
  Test module for ListDmUseCase
  """
  use WeCraft.DataCase, async: true

  alias WeCraft.Chats
  alias WeCraft.Chats.Infrastructure.ChatMemberRepositoryEcto

  import WeCraft.AccountsFixtures
  import WeCraft.ChatsFixtures

  describe "list_dm_chats/1" do
    test "returns all DM chats for a user" do
      user1 = user_fixture()
      user2 = user_fixture()
      user3 = user_fixture()

      # Create DM chats
      dm_chat1 = chat_fixture(%{type: "dm", is_public: false})
      dm_chat2 = chat_fixture(%{type: "dm", is_public: false})

      # Create a regular project chat (should not be included)
      _project_chat = chat_fixture(%{type: "channel", is_public: true})

      # Add user1 to both DM chats
      {:ok, _member1} =
        ChatMemberRepositoryEcto.create_chat_member(%{
          user_id: user1.id,
          chat_id: dm_chat1.id,
          joined_at: DateTime.utc_now()
        })

      {:ok, _member2} =
        ChatMemberRepositoryEcto.create_chat_member(%{
          user_id: user2.id,
          chat_id: dm_chat1.id,
          joined_at: DateTime.utc_now()
        })

      {:ok, _member3} =
        ChatMemberRepositoryEcto.create_chat_member(%{
          user_id: user1.id,
          chat_id: dm_chat2.id,
          joined_at: DateTime.utc_now()
        })

      {:ok, _member4} =
        ChatMemberRepositoryEcto.create_chat_member(%{
          user_id: user3.id,
          chat_id: dm_chat2.id,
          joined_at: DateTime.utc_now()
        })

      # Add messages to the chats
      _message1 = message_fixture(%{chat: dm_chat1, sender: user1, content: "Hello from chat 1"})
      _message2 = message_fixture(%{chat: dm_chat2, sender: user1, content: "Hello from chat 2"})

      # Test the use case
      params = %{user_id: user1.id, scope: %{user: user1}}

      assert {:ok, chats} = Chats.list_dm_chats(params)

      # Verify we get the correct chats
      assert length(chats) == 2
      chat_ids = Enum.map(chats, & &1.id) |> Enum.sort()
      expected_ids = [dm_chat1.id, dm_chat2.id] |> Enum.sort()
      assert chat_ids == expected_ids

      # Verify all chats are DM type
      Enum.each(chats, fn chat ->
        assert chat.type == "dm"
        assert chat.is_public == false
      end)

      # Verify members and messages are preloaded
      chat_with_user2 =
        Enum.find(chats, fn chat ->
          Enum.any?(chat.members, fn member -> member.user.id == user2.id end)
        end)

      assert length(chat_with_user2.members) == 2
      assert length(chat_with_user2.messages) == 1
      assert hd(chat_with_user2.messages).content == "Hello from chat 1"
    end

    test "returns empty list when user has no DM chats" do
      user = user_fixture()
      params = %{user_id: user.id, scope: %{user: user}}

      assert {:ok, chats} = Chats.list_dm_chats(params)
      assert chats == []
    end

    test "does not return regular project chats" do
      user1 = user_fixture()
      _user2 = user_fixture()

      # Create a project chat where user1 is a member
      project_chat = chat_fixture(%{type: "channel", is_public: true})

      {:ok, _member} =
        ChatMemberRepositoryEcto.create_chat_member(%{
          user_id: user1.id,
          chat_id: project_chat.id,
          joined_at: DateTime.utc_now()
        })

      params = %{user_id: user1.id, scope: %{user: user1}}

      assert {:ok, chats} = Chats.list_dm_chats(params)
      assert chats == []
    end
  end
end
