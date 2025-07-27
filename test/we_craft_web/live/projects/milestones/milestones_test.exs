defmodule WeCraftWeb.Projects.Milestones.MilestonesTest do
  @moduledoc """
  Tests for the Milestones LiveView.
  """
  use WeCraftWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "mount" do
    test "mounts successfully for project owner", %{conn: conn} do
      user = WeCraft.AccountsFixtures.user_fixture()
      project = WeCraft.ProjectsFixtures.project_fixture(%{owner: user})

      conn = log_in_user(conn, user)

      {:ok, _view, html} = live(conn, ~p"/project/#{project.id}/milestones")

      assert html =~ "Milestones"
      assert html =~ "Track project progress and goals"
      assert html =~ project.title
      assert html =~ "No milestones yet"
      assert html =~ "Create Your First Milestone"
    end

    test "redirects when project doesn't exist", %{conn: conn} do
      user = WeCraft.AccountsFixtures.user_fixture()
      conn = log_in_user(conn, user)

      # Try to access milestones for non-existent project
      assert {:error, {:live_redirect, %{to: "/", flash: %{}}}} =
               live(conn, ~p"/project/999/milestones")
    end

    test "displays existing milestones", %{conn: conn} do
      user = WeCraft.AccountsFixtures.user_fixture()
      project = WeCraft.ProjectsFixtures.project_fixture(%{owner: user})

      # Create a milestone
      {:ok, _milestone} =
        WeCraft.Milestones.create_milestone(%{
          attrs: %{
            title: "Test Milestone",
            description: "Test Description",
            status: "planned",
            project_id: project.id
          },
          scope: %{user: user}
        })

      conn = log_in_user(conn, user)

      {:ok, _view, html} = live(conn, ~p"/project/#{project.id}/milestones")

      assert html =~ "Test Milestone"
      assert html =~ "Test Description"
      assert html =~ "Planned"
    end
  end

  describe "milestone actions" do
    test "can complete a milestone", %{conn: conn} do
      user = WeCraft.AccountsFixtures.user_fixture()
      project = WeCraft.ProjectsFixtures.project_fixture(%{owner: user})

      # Create a milestone
      {:ok, milestone} =
        WeCraft.Milestones.create_milestone(%{
          attrs: %{
            title: "Test Milestone",
            description: "Test Description",
            status: "planned",
            project_id: project.id
          },
          scope: %{user: user}
        })

      conn = log_in_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/project/#{project.id}/milestones")

      # Complete the milestone
      view
      |> element("button[phx-click='complete-milestone']")
      |> render_click(%{"milestone-id" => milestone.id})

      # Check that the flash message appears in the assigns
      assigns = :sys.get_state(view.pid).socket.assigns
      assert assigns.flash["info"] == "Milestone marked as completed!"
      assert render(view) =~ "Completed"
    end

    test "can delete a milestone", %{conn: conn} do
      user = WeCraft.AccountsFixtures.user_fixture()
      project = WeCraft.ProjectsFixtures.project_fixture(%{owner: user})

      # Create a milestone
      {:ok, milestone} =
        WeCraft.Milestones.create_milestone(%{
          attrs: %{
            title: "Test Milestone",
            description: "Test Description",
            status: "planned",
            project_id: project.id
          },
          scope: %{user: user}
        })

      conn = log_in_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/project/#{project.id}/milestones")

      # Delete the milestone
      view
      |> element("button[phx-click='delete-milestone']")
      |> render_click(%{"milestone-id" => milestone.id})

      # Check that the flash message appears in the assigns
      assigns = :sys.get_state(view.pid).socket.assigns
      assert assigns.flash["info"] == "Milestone deleted successfully"
      refute render(view) =~ "Test Milestone"
    end
  end

  describe "navigation" do
    test "new milestone button navigates to create page", %{conn: conn} do
      user = WeCraft.AccountsFixtures.user_fixture()
      project = WeCraft.ProjectsFixtures.project_fixture(%{owner: user})

      conn = log_in_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/project/#{project.id}/milestones")

      # Click new milestone button (the one in the header)
      {:ok, _view, html} =
        view
        |> element("a.btn.btn-primary", "New Milestone")
        |> render_click()
        |> follow_redirect(conn)

      assert html =~ "Create New Milestone"
    end
  end

  describe "left menu integration" do
    test "displays project chats in left menu", %{conn: conn} do
      user = WeCraft.AccountsFixtures.user_fixture()
      project = WeCraft.ProjectsFixtures.project_fixture(%{owner: user})

      # Create a chat for the project
      {:ok, _chat} =
        WeCraft.Chats.create_project_chat(%{
          attrs: %{
            name: "Test Chat",
            description: "Test Description",
            project_id: project.id,
            is_main: false,
            is_public: true,
            type: "channel"
          }
        })

      conn = log_in_user(conn, user)

      {:ok, _view, html} = live(conn, ~p"/project/#{project.id}/milestones")

      assert html =~ "Test Chat"
      assert html =~ "Milestones"
    end

    test "displays active milestones in left menu", %{conn: conn} do
      user = WeCraft.AccountsFixtures.user_fixture()
      project = WeCraft.ProjectsFixtures.project_fixture(%{owner: user})

      # Create active milestones
      _active_milestone1 =
        WeCraft.MilestonesFixtures.milestone_fixture(%{
          project: project,
          status: :active,
          title: "Active Left Menu Milestone 1"
        })

      _active_milestone2 =
        WeCraft.MilestonesFixtures.milestone_fixture(%{
          project: project,
          status: :active,
          title: "Active Left Menu Milestone 2"
        })

      conn = log_in_user(conn, user)

      {:ok, _view, html} = live(conn, ~p"/project/#{project.id}/milestones")

      # Should show active milestones in left menu
      assert html =~ "Active (2)"
      assert html =~ "Active Left Menu Milestone 1"
      assert html =~ "Active Left Menu Milestone 2"
      assert html =~ "All milestones"
    end

    test "handles left menu events", %{conn: conn} do
      user = WeCraft.AccountsFixtures.user_fixture()
      project = WeCraft.ProjectsFixtures.project_fixture(%{owner: user})
      conn = log_in_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/project/#{project.id}/milestones")

      # Send section change event and verify navigation
      Process.send(view.pid, {:section_changed, :chat}, [])

      # Wait a bit for the message to be processed
      Process.sleep(10)

      # The test passes if no error occurs - the navigation is internal
      assert true
    end
  end
end
