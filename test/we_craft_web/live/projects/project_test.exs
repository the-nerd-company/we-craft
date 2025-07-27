defmodule WeCraftWeb.Projects.ProjectTest do
  @moduledoc """
  Tests for the main project page (focused on chat functionality).
  Project info functionality is now tested in project_info_test.exs.
  """
  use WeCraftWeb.ConnCase

  import Phoenix.LiveViewTest
  import WeCraft.AccountsFixtures
  import WeCraft.ProjectsFixtures
  import WeCraft.ChatsFixtures

  alias WeCraft.Accounts.Scope

  describe "mount/3" do
    setup :register_and_log_in_user

    test "loads project and chats successfully", %{conn: conn, user: user} do
      user = %{user | name: "Test User"}
      project = project_fixture(%{owner: user})
      _main_chat = chat_fixture(%{project: project, is_main: true})

      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))
      {:ok, _lv, html} = live(conn, ~p"/project/#{project.id}/channels")

      assert html =~ project.title
    end

    test "redirects when project not found", %{conn: conn, user: user} do
      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))

      # Should get an error redirect when project doesn't exist
      assert {:error, {:live_redirect, %{to: "/", flash: %{}}}} =
               live(conn, ~p"/project/99999")
    end

    test "loads with no chats when project has no chats", %{conn: conn, user: user} do
      user = %{user | name: "Test User"}
      project = project_fixture(%{owner: user})

      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))
      {:ok, lv, _html} = live(conn, ~p"/project/#{project.id}/channels")

      # Check that current_chat is nil when there are no chats
      assigns = :sys.get_state(lv.pid).socket.assigns
      assert assigns.current_chat == nil
      assert assigns.chats == []
    end

    test "sets first chat as current when multiple chats exist", %{conn: conn, user: user} do
      user = %{user | name: "Test User"}
      project = project_fixture(%{owner: user})

      # Create multiple chats
      main_chat = chat_fixture(%{project: project, is_main: true})
      _other_chat = chat_fixture(%{project: project, name: "other-channel"})

      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))
      {:ok, lv, _html} = live(conn, ~p"/project/#{project.id}/channels")

      # Check that the first chat (main_chat) is set as current
      assigns = :sys.get_state(lv.pid).socket.assigns
      assert assigns.current_chat.id == main_chat.id
      assert length(assigns.chats) == 2
    end
  end

  describe "render/1" do
    setup :register_and_log_in_user

    test "renders project chat interface", %{conn: conn, user: user} do
      # Make sure the user has a name
      user = %{user | name: "Test User"}

      project = project_fixture(%{owner: user, title: "Awesome Project"})

      # Create a main chat for the project
      _main_chat = chat_fixture(%{project: project, is_main: true})

      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))
      {:ok, _lv, html} = live(conn, ~p"/project/#{project.id}/channels")

      # Check that the project title appears in the left menu
      assert html =~ "Awesome Project"
      # Check that chat interface is rendered
      assert html =~ "Main Chat"
      # Check that left menu components are present
      assert html =~ "Project Info"
      assert html =~ "Channels"
      assert html =~ "Milestones"
    end

    test "renders edit button in dropdown for project owner", %{conn: conn, user: user} do
      # Make sure the user has a name
      user = %{user | name: "Test User"}
      project = project_fixture(%{owner: user})

      # Create a main chat for the project
      _main_chat = chat_fixture(%{project: project, is_main: true})

      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))
      {:ok, _lv, html} = live(conn, ~p"/project/#{project.id}/channels")

      # Owner should see edit button in the left menu dropdown
      assert html =~ "Edit"
      assert html =~ ~s(href="/project/#{project.id}/edit")
    end

    test "does not render edit button for non-owner", %{conn: conn} do
      # Create another user as the project owner
      owner = user_fixture() |> Map.put(:name, "Project Owner")
      project = project_fixture(%{owner: owner})

      # Create a main chat for the project
      _main_chat = chat_fixture(%{project: project, is_main: true})

      # Log in as a different user
      different_user = user_fixture() |> Map.put(:name, "Different User")
      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(different_user))

      {:ok, _lv, html} = live(conn, ~p"/project/#{project.id}/channels")

      # Non-owner should not see edit button
      refute html =~ ~s(href="/project/#{project.id}/edit")
    end
  end

  describe "handle_info/2 - new messages" do
    setup :register_and_log_in_user

    test "sends update to chat component when new message arrives", %{conn: conn, user: user} do
      # Make sure the user has a name
      user = %{user | name: "Test User"}
      project = project_fixture(%{owner: user})

      # Create a main chat for the project
      _main_chat =
        chat_fixture(%{project: project, is_main: true, type: "channel", is_public: true})

      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))
      {:ok, lv, _html} = live(conn, ~p"/project/#{project.id}/channels")

      # Create a new message
      message = %{
        id: 1,
        content: "Test message",
        sender_id: user.id,
        sender: user,
        timestamp: NaiveDateTime.utc_now()
      }

      # Send new message info to the LiveView
      send(lv.pid, {:new_message, message})

      # This is hard to test directly since it sends an update to a child component
      # We can check that the LiveView process doesn't crash
      Process.info(lv.pid)
      assert is_pid(lv.pid)
      assert Process.alive?(lv.pid)
    end
  end
end
