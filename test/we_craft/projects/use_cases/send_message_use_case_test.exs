defmodule WeCraft.Chats.UseCases.SendMessageUseCaseTest do
  @moduledoc """
  Test for the SendMessageUseCase.
  """
  use WeCraft.DataCase, async: true

  alias WeCraft.FixtureHelper
  alias WeCraft.Chats.{Chat, Message}
  alias WeCraft.Chats.UseCases.SendMessageUseCase
  import WeCraft.AccountsFixtures
  import WeCraft.ProjectsFixtures

  describe "send_message/1" do
    setup do
      user = user_fixture()
      project = project_fixture(%{owner: user})

      # Create a chat for the project
      chat =
        create_chat(%{project_id: project.id, is_main: true, room_uuid: Ecto.UUID.generate()})

      # Mock the PubSub system to verify broadcasting
      test_pid = self()

      # Use Mox to mock the ChatBroadcaster
      expect_broadcast = fn chat_id, message ->
        send(test_pid, {:broadcast, chat_id, message})
        :ok
      end

      %{
        user: user,
        project: project,
        chat: chat,
        expect_broadcast: expect_broadcast
      }
    end

    test "successfully sends a message", %{user: user, chat: chat} do
      message_attrs = %{
        content: "Hello, this is a test message",
        sender_id: user.id,
        chat_id: chat.id
      }

      assert {:ok, message} = SendMessageUseCase.send_message(message_attrs)

      # Verify the message was saved with correct attributes
      assert message.content == message_attrs.content
      assert message.sender_id == user.id
      assert message.chat_id == chat.id
      assert message.timestamp != nil

      # Verify the message has the sender association loaded
      assert message.sender != nil
      assert message.sender.id == user.id

      # Verify the message exists in the database
      db_message = WeCraft.Repo.get(Message, message.id)
      assert db_message != nil
      assert db_message.content == message_attrs.content
    end

    test "returns error with invalid attributes" do
      # Missing required fields
      invalid_attrs = %{
        content: "Test message"
        # Missing sender_id and chat_id
      }

      assert {:error, changeset} = SendMessageUseCase.send_message(invalid_attrs)
      assert errors_on(changeset).sender_id != nil
      assert errors_on(changeset).chat_id != nil

      # Empty content
      invalid_attrs = %{
        content: "",
        sender_id: 1,
        chat_id: 1
      }

      assert {:error, changeset} = SendMessageUseCase.send_message(invalid_attrs)
      assert errors_on(changeset).content != nil
    end

    test "raises error with non-existent foreign keys" do
      # This test verifies that attempting to create a message with non-existent foreign keys
      # results in a constraint error, as expected by Ecto's behavior without custom constraint handling
      invalid_attrs = %{
        content: "Test message",
        # Non-existent ID
        sender_id: 999_999_999,
        # Non-existent ID
        chat_id: 999_999_999
      }

      assert_raise Ecto.ConstraintError, fn ->
        SendMessageUseCase.send_message(invalid_attrs)
      end
    end
  end

  # Helper functions to create test data

  defp create_chat(attrs) do
    FixtureHelper.insert_entity(
      Chat,
      %{is_main: false, type: "channel", is_public: true},
      attrs
    )
  end
end
