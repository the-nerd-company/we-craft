defmodule WeCraft.Chats.UseCases.ListProjectChatsUseCaseTest do
  @moduledoc """
  Test for the ListProjectChatsUseCase.
  """
  use WeCraft.DataCase, async: true

  alias WeCraft.Chats
  alias WeCraft.Chats.{Chat, Message}

  alias WeCraft.FixtureHelper
  import WeCraft.AccountsFixtures
  import WeCraft.ProjectsFixtures

  describe "list_project_chats/1" do
    setup do
      user = user_fixture()
      project1 = project_fixture(%{owner: user})
      project2 = project_fixture(%{owner: user})

      # Create multiple chats for project1
      main_chat =
        create_chat(%{project_id: project1.id, is_main: true, room_uuid: Ecto.UUID.generate()})

      secondary_chat =
        create_chat(%{project_id: project1.id, is_main: false, room_uuid: Ecto.UUID.generate()})

      # Create a message for the main chat
      message =
        create_message(%{
          chat_id: main_chat.id,
          sender_id: user.id,
          content: "Hello world"
        })

      # Create a chat for project2 to ensure isolation
      other_chat =
        create_chat(%{project_id: project2.id, is_main: true, room_uuid: Ecto.UUID.generate()})

      %{
        user: user,
        project1: project1,
        project2: project2,
        main_chat: main_chat,
        secondary_chat: secondary_chat,
        other_chat: other_chat,
        message: message
      }
    end

    test "returns a list of chats for a given project", %{
      project1: project1,
      main_chat: main_chat,
      secondary_chat: secondary_chat,
      message: message
    } do
      {:ok, chats} = Chats.list_project_chats(%{project_id: project1.id})

      assert length(chats) == 2

      # Convert to maps with IDs for easier comparison
      chat_ids = Enum.map(chats, & &1.id) |> Enum.sort()
      expected_ids = [main_chat.id, secondary_chat.id] |> Enum.sort()

      assert chat_ids == expected_ids

      # Check that messages are properly preloaded
      main_chat_from_result = Enum.find(chats, &(&1.id == main_chat.id))
      assert length(main_chat_from_result.messages) == 1
      assert hd(main_chat_from_result.messages).content == message.content

      # Check that sender is properly preloaded in messages
      assert hd(main_chat_from_result.messages).sender.id == message.sender_id
    end

    test "returns an empty list for a project without chats" do
      new_project = project_fixture()

      {:ok, chats} = Chats.list_project_chats(%{project_id: new_project.id})

      assert chats == []
    end

    test "returns only chats for the specified project", %{
      project1: project1,
      project2: project2,
      main_chat: main_chat,
      secondary_chat: secondary_chat,
      other_chat: other_chat
    } do
      # Get chats for project1
      {:ok, project1_chats} =
        Chats.list_project_chats(%{project_id: project1.id})

      project1_chat_ids = Enum.map(project1_chats, & &1.id) |> MapSet.new()

      # Get chats for project2
      {:ok, project2_chats} =
        Chats.list_project_chats(%{project_id: project2.id})

      project2_chat_ids = Enum.map(project2_chats, & &1.id) |> MapSet.new()

      # Verify the correct chats are returned for each project
      assert MapSet.size(project1_chat_ids) == 2
      assert main_chat.id in project1_chat_ids
      assert secondary_chat.id in project1_chat_ids
      refute other_chat.id in project1_chat_ids

      assert MapSet.size(project2_chat_ids) == 1
      assert other_chat.id in project2_chat_ids
      refute main_chat.id in project2_chat_ids
      refute secondary_chat.id in project2_chat_ids
    end

    test "returns an empty list for a non-existent project" do
      non_existent_id = -1

      {:ok, chats} = Chats.list_project_chats(%{project_id: non_existent_id})

      assert chats == []
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

  defp create_message(attrs) do
    timestamp = DateTime.utc_now()

    FixtureHelper.insert_entity(
      Message,
      %{
        content: "Test message",
        timestamp: timestamp
      },
      attrs
    )
  end
end
