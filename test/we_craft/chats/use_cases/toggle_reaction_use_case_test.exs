defmodule WeCraft.Chats.UseCases.ToggleReactionUseCaseTest do
  @moduledoc """
  Tests for ToggleReactionUseCase functionality.
  """
  use WeCraft.DataCase

  alias WeCraft.Chats

  import WeCraft.ChatsFixtures
  import WeCraft.AccountsFixtures

  describe "toggle_reaction/1" do
    test "adds reaction if it doesn't exist" do
      user = user_fixture()
      message = message_fixture()

      params = %{
        message_id: message.id,
        emoji: "👍",
        user_id: user.id
      }

      assert {:ok, updated_message} = Chats.toggle_reaction(params)
      assert length(updated_message.reactions) == 1

      reaction = hd(updated_message.reactions)
      assert reaction["emoji"] == "👍"
      assert reaction["users"] == [user.id]
    end

    test "removes user from existing reaction" do
      user = user_fixture()

      message =
        message_fixture(%{
          reactions: [%{"emoji" => "👍", "users" => [user.id]}]
        })

      params = %{
        message_id: message.id,
        emoji: "👍",
        user_id: user.id
      }

      assert {:ok, updated_message} = Chats.toggle_reaction(params)
      assert updated_message.reactions == []
    end

    test "removes entire reaction when last user is removed" do
      user1 = user_fixture()
      user2 = user_fixture()

      message =
        message_fixture(%{
          reactions: [%{"emoji" => "👍", "users" => [user1.id, user2.id]}]
        })

      # Remove user1
      params = %{
        message_id: message.id,
        emoji: "👍",
        user_id: user1.id
      }

      assert {:ok, updated_message} = Chats.toggle_reaction(params)
      assert length(updated_message.reactions) == 1

      reaction = hd(updated_message.reactions)
      assert reaction["emoji"] == "👍"
      assert reaction["users"] == [user2.id]

      # Remove user2 (last user)
      params = %{
        message_id: message.id,
        emoji: "👍",
        user_id: user2.id
      }

      assert {:ok, final_message} = Chats.toggle_reaction(params)
      assert final_message.reactions == []
    end

    test "adds user to existing reaction if not present" do
      user1 = user_fixture()
      user2 = user_fixture()

      message =
        message_fixture(%{
          reactions: [%{"emoji" => "👍", "users" => [user1.id]}]
        })

      params = %{
        message_id: message.id,
        emoji: "👍",
        user_id: user2.id
      }

      assert {:ok, updated_message} = Chats.toggle_reaction(params)
      assert length(updated_message.reactions) == 1

      reaction = hd(updated_message.reactions)
      assert reaction["emoji"] == "👍"
      assert user1.id in reaction["users"]
      assert user2.id in reaction["users"]
      assert length(reaction["users"]) == 2
    end

    test "handles multiple different reactions" do
      user = user_fixture()

      message =
        message_fixture(%{
          reactions: [
            %{"emoji" => "👍", "users" => [user.id]},
            %{"emoji" => "❤️", "users" => [user.id]}
          ]
        })

      # Toggle off thumbs up
      params = %{
        message_id: message.id,
        emoji: "👍",
        user_id: user.id
      }

      assert {:ok, updated_message} = Chats.toggle_reaction(params)
      assert length(updated_message.reactions) == 1

      remaining_reaction = hd(updated_message.reactions)
      assert remaining_reaction["emoji"] == "❤️"
      assert remaining_reaction["users"] == [user.id]
    end

    test "returns error for non-existent message" do
      user = user_fixture()

      params = %{
        message_id: -1,
        emoji: "👍",
        user_id: user.id
      }

      assert {:error, :message_not_found} = Chats.toggle_reaction(params)
    end

    test "preloads sender association" do
      user = user_fixture()
      message = message_fixture()

      params = %{
        message_id: message.id,
        emoji: "👍",
        user_id: user.id
      }

      assert {:ok, updated_message} = Chats.toggle_reaction(params)
      assert %WeCraft.Accounts.User{} = updated_message.sender
    end
  end
end
