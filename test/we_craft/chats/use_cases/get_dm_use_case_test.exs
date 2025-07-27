defmodule WeCraft.Chats.UseCases.GetDmUseCaseTest do
  @moduledoc """
  Test module for GetDmUseCase
  """
  use WeCraft.DataCase, async: true

  alias WeCraft.Chats
  alias WeCraft.Chats.Infrastructure.ChatMemberRepositoryEcto
  alias WeCraft.Chats.UseCases.GetDmUseCase

  import WeCraft.AccountsFixtures
  import WeCraft.ChatsFixtures

  describe "get_dm_chat/1" do
    test "returns a DM chat with members and messages preloaded" do
      user1 = user_fixture()
      user2 = user_fixture()

      # Create a DM chat
      chat = chat_fixture(%{type: "dm", is_public: false})

      # Add members to the chat
      {:ok, _member1} =
        ChatMemberRepositoryEcto.create_chat_member(%{
          user_id: user1.id,
          chat_id: chat.id,
          joined_at: DateTime.utc_now()
        })

      {:ok, _member2} =
        ChatMemberRepositoryEcto.create_chat_member(%{
          user_id: user2.id,
          chat_id: chat.id,
          joined_at: DateTime.utc_now()
        })

      # Add a message
      message = message_fixture(%{chat: chat, sender: user1})

      # Test the use case
      params = %{chat_id: chat.id, scope: %{user: user1}}

      assert {:ok, returned_chat} = GetDmUseCase.get_dm_chat(params)

      # Verify the chat is returned with proper associations
      assert returned_chat.id == chat.id
      assert returned_chat.type == "dm"
      assert returned_chat.is_public == false

      # Verify members are preloaded
      assert length(returned_chat.members) == 2
      member_user_ids = Enum.map(returned_chat.members, & &1.user.id)
      assert user1.id in member_user_ids
      assert user2.id in member_user_ids

      # Verify messages are preloaded
      assert length(returned_chat.messages) == 1
      assert hd(returned_chat.messages).id == message.id
      assert hd(returned_chat.messages).sender.id == user1.id
    end

    test "raises error for non-existent chat" do
      user = user_fixture()
      params = %{chat_id: 999_999, scope: %{user: user}}

      assert_raise Ecto.NoResultsError, fn ->
        Chats.get_dm_chat(params)
      end
    end
  end
end
