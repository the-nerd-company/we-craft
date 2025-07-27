defmodule WeCraft.Chats.UseCases.AddReactionUseCaseTest do
  @moduledoc """
  Tests for AddReactionUseCase functionality.
  """
  use WeCraft.DataCase, async: true

  alias WeCraft.Chats.UseCases.AddReactionUseCase

  import WeCraft.ChatsFixtures
  import WeCraft.AccountsFixtures

  describe "add_reaction/1" do
    test "adds a new reaction to a message" do
      user = user_fixture()
      message = message_fixture()

      params = %{
        message_id: message.id,
        emoji: "👍",
        user_id: user.id
      }

      assert {:ok, updated_message} = AddReactionUseCase.add_reaction(params)
      assert length(updated_message.reactions) == 1

      reaction = hd(updated_message.reactions)
      assert reaction["emoji"] == "👍"
      assert reaction["users"] == [user.id]
    end

    test "adds user to existing reaction" do
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

      assert {:ok, updated_message} = AddReactionUseCase.add_reaction(params)
      assert length(updated_message.reactions) == 1

      reaction = hd(updated_message.reactions)
      assert reaction["emoji"] == "👍"
      assert user1.id in reaction["users"]
      assert user2.id in reaction["users"]
      assert length(reaction["users"]) == 2
    end

    test "does not duplicate user in existing reaction" do
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

      assert {:ok, updated_message} = AddReactionUseCase.add_reaction(params)
      assert length(updated_message.reactions) == 1

      reaction = hd(updated_message.reactions)
      assert reaction["emoji"] == "👍"
      assert reaction["users"] == [user.id]
    end

    test "adds different emoji reaction" do
      user = user_fixture()

      message =
        message_fixture(%{
          reactions: [%{"emoji" => "👍", "users" => [user.id]}]
        })

      params = %{
        message_id: message.id,
        emoji: "❤️",
        user_id: user.id
      }

      assert {:ok, updated_message} = AddReactionUseCase.add_reaction(params)
      assert length(updated_message.reactions) == 2

      emojis = Enum.map(updated_message.reactions, & &1["emoji"])
      assert "👍" in emojis
      assert "❤️" in emojis
    end

    test "returns error for non-existent message" do
      user = user_fixture()

      params = %{
        message_id: -1,
        emoji: "👍",
        user_id: user.id
      }

      assert {:error, :message_not_found} = AddReactionUseCase.add_reaction(params)
    end

    test "preloads sender association" do
      user = user_fixture()
      message = message_fixture()

      params = %{
        message_id: message.id,
        emoji: "👍",
        user_id: user.id
      }

      assert {:ok, updated_message} = AddReactionUseCase.add_reaction(params)
      assert %WeCraft.Accounts.User{} = updated_message.sender
    end
  end
end
