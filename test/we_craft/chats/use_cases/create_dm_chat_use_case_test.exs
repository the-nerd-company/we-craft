defmodule WeCraft.Chats.UseCases.CreateDmChatUseCaseTest do
  @moduledoc """
  Test for the CreateDmChatUseCase.
  """
  use WeCraft.DataCase, async: true

  alias WeCraft.Chats
  alias WeCraft.Chats.Infrastructure.ChatRepositoryEcto

  import WeCraft.AccountsFixtures
  import WeCraft.ChatsFixtures

  describe "create_dm_chat/1" do
    test "denies creating DM chat without permission" do
      user = user_fixture()
      other_user = user_fixture()
      recipient = user_fixture()

      params = %{
        attrs: %{
          sender_id: user.id,
          recipient_id: recipient.id
        },
        scope: %{
          # Different user trying to create DM
          user: other_user
        }
      }

      assert {:error, :permission_denied} = Chats.create_dm_chat(params)
    end

    test "returns existing DM chat when one already exists" do
      user = user_fixture()
      recipient = user_fixture()

      # Create an existing DM chat between the users
      existing_chat = dm_chat_fixture(%{user1: user, user2: recipient})

      params = %{
        attrs: %{
          sender_id: user.id,
          recipient_id: recipient.id
        },
        scope: %{
          user: user
        }
      }

      assert {:ok, chat} = Chats.create_dm_chat(params)
      assert chat.id == existing_chat.id
      assert chat.type == "dm"
    end

    test "returns existing DM chat regardless of sender/recipient order" do
      user = user_fixture()
      recipient = user_fixture()

      # Create an existing DM chat between the users
      existing_chat = dm_chat_fixture(%{user1: user, user2: recipient})

      # Try to create from recipient to user (reversed order)
      params = %{
        attrs: %{
          sender_id: recipient.id,
          recipient_id: user.id
        },
        scope: %{
          user: recipient
        }
      }

      assert {:ok, chat} = Chats.create_dm_chat(params)
      assert chat.id == existing_chat.id
      assert chat.type == "dm"
    end

    test "creates a new DM chat when none exists" do
      user = user_fixture()
      recipient = user_fixture()

      params = %{
        attrs: %{
          sender_id: user.id,
          recipient_id: recipient.id
        },
        scope: %{
          user: user
        }
      }

      # Ensure no DM chat exists initially
      assert ChatRepositoryEcto.get_dm_chat(%{sender_id: user.id, recipient_id: recipient.id}) ==
               nil

      assert {:ok, chat} = Chats.create_dm_chat(params)

      # Verify the created chat
      assert chat.project_id == nil
      assert chat.type == "dm"
      assert chat.is_public == false
      assert chat.is_main == false

      # Verify it can be found by the repository
      found_chat =
        ChatRepositoryEcto.get_dm_chat(%{sender_id: user.id, recipient_id: recipient.id})

      assert found_chat.id == chat.id
    end

    test "creates chat with correct members" do
      user = user_fixture()
      recipient = user_fixture()

      params = %{
        attrs: %{
          sender_id: user.id,
          recipient_id: recipient.id
        },
        scope: %{
          user: user
        }
      }

      assert {:ok, chat} = Chats.create_dm_chat(params)

      # Load the chat with members to verify
      chat_with_members = ChatRepositoryEcto.get_chat!(chat.id)

      assert length(chat_with_members.members) == 2
      member_user_ids = Enum.map(chat_with_members.members, & &1.user_id)
      assert user.id in member_user_ids
      assert recipient.id in member_user_ids
    end

    test "handles permission check correctly for sender" do
      user = user_fixture()
      recipient = user_fixture()

      params = %{
        attrs: %{
          sender_id: user.id,
          recipient_id: recipient.id
        },
        scope: %{
          # Same user as sender
          user: user
        }
      }

      # Should succeed since user is the sender
      assert {:ok, _chat} = Chats.create_dm_chat(params)
    end

    test "returns existing chat when chat parameter is provided" do
      user = user_fixture()
      recipient = user_fixture()
      existing_chat = dm_chat_fixture(%{user1: user, user2: recipient})

      params = %{
        attrs: %{
          sender_id: user.id,
          recipient_id: recipient.id
        },
        # Providing existing chat directly
        chat: existing_chat,
        scope: %{
          user: user
        }
      }

      assert {:ok, chat} = Chats.create_dm_chat(params)
      assert chat.id == existing_chat.id
    end
  end
end
