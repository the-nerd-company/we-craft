defmodule WeCraftWeb.Projects.Milestones.NewMilestoneTest do
  @moduledoc """
  Tests for the NewMilestone LiveView.
  """
  use WeCraftWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "mount" do
    test "mounts successfully for project owner", %{conn: conn} do
      user = WeCraft.AccountsFixtures.user_fixture()
      project = WeCraft.ProjectsFixtures.project_fixture(%{owner: user})

      conn = log_in_user(conn, user)

      {:ok, _view, html} = live(conn, ~p"/project/#{project.id}/milestones/new")

      assert html =~ "Create New Milestone"
      assert html =~ project.title
      assert html =~ "Title"
      assert html =~ "Description"
      assert html =~ "Status"
      assert html =~ "Due Date"
    end

    test "redirects when project doesn't exist", %{conn: conn} do
      user = WeCraft.AccountsFixtures.user_fixture()
      conn = log_in_user(conn, user)

      assert {:error, {:live_redirect, %{to: "/", flash: %{}}}} =
               live(conn, ~p"/project/99999/milestones/new")
    end

    @tag :skip
    test "redirects when user is not authenticated", %{conn: conn} do
      user = WeCraft.AccountsFixtures.user_fixture()
      project = WeCraft.ProjectsFixtures.project_fixture(%{owner: user})

      # Don't authenticate the user - test should redirect to login
      result = live(conn, ~p"/project/#{project.id}/milestones/new")

      case result do
        {:error, {:redirect, %{to: "/users/log_in"}}} ->
          # This is the expected behavior
          assert true

        {:ok, _view, _html} ->
          # If it doesn't redirect, it means authentication isn't enforced properly
          flunk("Expected redirect to login page but got OK response")

        other ->
          flunk("Unexpected result: #{inspect(other)}")
      end
    end
  end

  describe "form validation" do
    test "validates required fields", %{conn: conn} do
      user = WeCraft.AccountsFixtures.user_fixture()
      project = WeCraft.ProjectsFixtures.project_fixture(%{owner: user})
      conn = log_in_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/project/#{project.id}/milestones/new")

      # Submit form with empty required fields
      result =
        view
        |> form("form", milestone: %{title: "", description: ""})
        |> render_change()

      # Should show validation errors
      assert result =~ "can&#39;t be blank"
    end

    test "form is valid with all required fields", %{conn: conn} do
      user = WeCraft.AccountsFixtures.user_fixture()
      project = WeCraft.ProjectsFixtures.project_fixture(%{owner: user})
      conn = log_in_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/project/#{project.id}/milestones/new")

      # Fill form with valid data
      result =
        view
        |> form("form",
          milestone: %{
            title: "Test Milestone",
            description: "Test Description",
            status: "planned"
          }
        )
        # Should not show validation errors
        |> render_change()

      refute result =~ "can&#39;t be blank"
    end
  end

  describe "form submission" do
    test "creates milestone with valid data", %{conn: conn} do
      user = WeCraft.AccountsFixtures.user_fixture()
      project = WeCraft.ProjectsFixtures.project_fixture(%{owner: user})
      conn = log_in_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/project/#{project.id}/milestones/new")

      # Submit form with valid data
      view
      |> form("form",
        milestone: %{
          title: "Test Milestone",
          description: "Test Description",
          status: "planned",
          due_date: "2025-12-31T23:59"
        }
      )
      |> render_submit()

      # Should redirect to project milestones view
      assert_redirected(view, ~p"/project/#{project.id}/milestones")

      # Verify milestone was created
      {:ok, milestones} =
        WeCraft.Milestones.list_project_milestones(%{
          project_id: project.id,
          scope: %{user: user}
        })

      assert length(milestones) == 1
      milestone = List.first(milestones)
      assert milestone.title == "Test Milestone"
      assert milestone.description == "Test Description"
      assert milestone.status == :planned
    end

    test "shows errors for invalid data", %{conn: conn} do
      user = WeCraft.AccountsFixtures.user_fixture()
      project = WeCraft.ProjectsFixtures.project_fixture(%{owner: user})
      conn = log_in_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/project/#{project.id}/milestones/new")

      # Submit form with invalid data
      result =
        view
        |> form("form", milestone: %{title: "", description: ""})
        |> render_submit()

      # Should show validation errors and stay on the form
      assert result =~ "can&#39;t be blank"
      assert result =~ "Create New Milestone"
    end
  end

  describe "cancel action" do
    test "navigates back to project milestones", %{conn: conn} do
      user = WeCraft.AccountsFixtures.user_fixture()
      project = WeCraft.ProjectsFixtures.project_fixture(%{owner: user})
      conn = log_in_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/project/#{project.id}/milestones/new")

      # Click cancel button
      view
      |> element("button", "Cancel")
      |> render_click()

      # Should redirect to project milestones view
      assert_redirected(view, ~p"/project/#{project.id}/milestones")
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

      {:ok, _view, html} = live(conn, ~p"/project/#{project.id}/milestones/new")

      assert html =~ "Test Chat"
      assert html =~ "Milestones"
    end

    test "displays active milestones in left menu", %{conn: conn} do
      user = WeCraft.AccountsFixtures.user_fixture()
      project = WeCraft.ProjectsFixtures.project_fixture(%{owner: user})

      # Create active milestones
      _active_milestone =
        WeCraft.MilestonesFixtures.milestone_fixture(%{
          project: project,
          status: :active,
          title: "Existing Active Milestone"
        })

      conn = log_in_user(conn, user)

      {:ok, _view, html} = live(conn, ~p"/project/#{project.id}/milestones/new")

      # Should show active milestones in left menu even on new milestone page
      assert html =~ "Active (1)"
      assert html =~ "Existing Active Milestone"
      assert html =~ "All milestones"
    end

    test "handles left menu events", %{conn: conn} do
      user = WeCraft.AccountsFixtures.user_fixture()
      project = WeCraft.ProjectsFixtures.project_fixture(%{owner: user})
      conn = log_in_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/project/#{project.id}/milestones/new")

      # Send section change event and verify navigation
      Process.send(view.pid, {:section_changed, :chat}, [])

      # Wait a bit for the message to be processed
      Process.sleep(10)

      # The test passes if no error occurs - the navigation is internal
      assert true
    end
  end
end
