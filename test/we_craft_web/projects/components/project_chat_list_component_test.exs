defmodule WeCraftWeb.Projects.Components.ProjectChatListComponentTest do
  @moduledoc """
  Tests for the ProjectChatListComponent.
  """
  use WeCraftWeb.ConnCase

  import Phoenix.LiveViewTest

  alias WeCraft.AccountsFixtures
  alias WeCraft.ProjectsFixtures
  alias WeCraftWeb.Projects.Components.ProjectChatListComponent

  describe "ProjectChatListComponent" do
    setup do
      # Create users for testing permissions
      owner_user = AccountsFixtures.user_fixture()
      different_user = AccountsFixtures.user_fixture()

      owner_scope = AccountsFixtures.user_scope_fixture(owner_user)
      different_user_scope = AccountsFixtures.user_scope_fixture(different_user)
      nil_scope = nil

      # Create a proper Project struct using fixtures
      project = ProjectsFixtures.project_fixture(%{owner: owner_user})

      # Mock chats
      chats = [
        %{
          id: 1,
          name: "General Discussion",
          description: "Main project chat",
          is_main: true,
          messages: [
            %{id: 1, content: "Hello team!"}
          ]
        },
        %{
          id: 2,
          name: "Backend Development",
          description: "Backend team chat",
          is_main: false,
          messages: [
            %{id: 2, content: "API is ready for review"}
          ]
        }
      ]

      current_chat = List.first(chats)

      %{
        project: project,
        chats: chats,
        current_chat: current_chat,
        owner_scope: owner_scope,
        different_user_scope: different_user_scope,
        nil_scope: nil_scope
      }
    end

    test "renders project chat list with chats", %{
      project: project,
      chats: chats,
      current_chat: current_chat,
      owner_scope: owner_scope
    } do
      rendered =
        render_component(ProjectChatListComponent, %{
          id: "test-chat-list",
          project: project,
          chats: chats,
          current_chat: current_chat,
          current_scope: owner_scope
        })

      assert rendered =~ "Project Chats"
      assert rendered =~ project.title
      # is_main takes precedence over name
      assert rendered =~ "Main Chat"
      assert rendered =~ "Backend Development"
      # description shows correctly
      assert rendered =~ "General project discussion"
      assert rendered =~ "Backend team chat"
    end

    test "renders empty state when no chats available", %{
      project: project,
      owner_scope: owner_scope
    } do
      rendered =
        render_component(ProjectChatListComponent, %{
          id: "test-chat-list",
          project: project,
          chats: [],
          current_chat: nil,
          current_scope: owner_scope
        })

      assert rendered =~ "Project Chats"
      assert rendered =~ project.title
      assert rendered =~ "No chats available"
    end

    test "highlights selected chat", %{
      project: project,
      chats: chats,
      current_chat: current_chat,
      owner_scope: owner_scope
    } do
      rendered =
        render_component(ProjectChatListComponent, %{
          id: "test-chat-list",
          project: project,
          chats: chats,
          current_chat: current_chat,
          current_scope: owner_scope
        })

      # Should highlight the current chat (first one)
      assert rendered =~ "bg-primary/10 border-l-4 border-l-primary"
    end

    test "handles chat display names correctly", %{
      project: project,
      chats: chats,
      owner_scope: owner_scope
    } do
      # Test with a chat that has no name
      chat_without_name = %{
        id: 3,
        name: nil,
        description: "Test chat",
        is_main: false,
        messages: []
      }

      chats_with_unnamed = chats ++ [chat_without_name]

      rendered =
        render_component(ProjectChatListComponent, %{
          id: "test-chat-list",
          project: project,
          chats: chats_with_unnamed,
          current_chat: List.first(chats_with_unnamed),
          current_scope: owner_scope
        })

      # is_main chat
      assert rendered =~ "Main Chat"
      # named chat
      assert rendered =~ "Backend Development"
      # unnamed chat fallback
      assert rendered =~ "Chat #3"
    end

    test "displays last message preview", %{
      project: project,
      chats: chats,
      current_chat: current_chat,
      owner_scope: owner_scope
    } do
      rendered =
        render_component(ProjectChatListComponent, %{
          id: "test-chat-list",
          project: project,
          chats: chats,
          current_chat: current_chat,
          current_scope: owner_scope
        })

      assert rendered =~ "Last: Hello team!"
      assert rendered =~ "Last: API is ready for review"
    end

    test "shows New Channel button when user has permission (project owner)", %{
      project: project,
      chats: chats,
      current_chat: current_chat,
      owner_scope: owner_scope
    } do
      rendered =
        render_component(ProjectChatListComponent, %{
          id: "test-chat-list",
          project: project,
          chats: chats,
          current_chat: current_chat,
          current_scope: owner_scope
        })

      assert rendered =~ "New Channel"
    end

    test "hides New Channel button when user has no permission (different user)", %{
      project: project,
      chats: chats,
      current_chat: current_chat,
      different_user_scope: different_user_scope
    } do
      rendered =
        render_component(ProjectChatListComponent, %{
          id: "test-chat-list",
          project: project,
          chats: chats,
          current_chat: current_chat,
          current_scope: different_user_scope
        })

      refute rendered =~ "New Channel"
    end

    test "hides New Channel button when current_scope is nil", %{
      project: project,
      chats: chats,
      current_chat: current_chat,
      nil_scope: nil_scope
    } do
      rendered =
        render_component(ProjectChatListComponent, %{
          id: "test-chat-list",
          project: project,
          chats: chats,
          current_chat: current_chat,
          current_scope: nil_scope
        })

      refute rendered =~ "New Channel"
    end
  end
end
