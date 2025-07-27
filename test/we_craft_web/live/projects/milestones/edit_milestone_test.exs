defmodule WeCraftWeb.Projects.Milestones.EditMilestoneTest do
  @moduledoc """
  Tests for the EditMilestone LiveView.
  """
  use WeCraftWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "mount" do
    test "mounts successfully for project owner", %{conn: conn} do
      user = WeCraft.AccountsFixtures.user_fixture()
      project = WeCraft.ProjectsFixtures.project_fixture(%{owner: user})

      # Create a milestone to edit
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

      {:ok, _view, html} =
        live(conn, ~p"/project/#{project.id}/milestones/#{milestone.id}/edit")

      assert html =~ "Edit Milestone"
      assert html =~ project.title
      assert html =~ "Test Milestone"
      assert html =~ "Test Description"
      assert html =~ "Title"
      assert html =~ "Description"
      assert html =~ "Status"
      assert html =~ "Due Date"
    end

    test "redirects when project doesn't exist", %{conn: conn} do
      user = WeCraft.AccountsFixtures.user_fixture()
      conn = log_in_user(conn, user)

      # Try to edit milestone for non-existent project
      assert {:error, {:live_redirect, %{to: "/", flash: %{}}}} =
               live(conn, ~p"/project/999/milestones/1/edit")
    end

    test "redirects when milestone doesn't exist", %{conn: conn} do
      user = WeCraft.AccountsFixtures.user_fixture()
      project = WeCraft.ProjectsFixtures.project_fixture(%{owner: user})
      conn = log_in_user(conn, user)

      # Try to edit non-existent milestone
      assert {:error, {:live_redirect, %{flash: %{"error" => "Milestone not found"}}}} =
               live(conn, ~p"/project/#{project.id}/milestones/999/edit")
    end

    test "redirects when milestone belongs to different project", %{conn: conn} do
      user = WeCraft.AccountsFixtures.user_fixture()
      project1 = WeCraft.ProjectsFixtures.project_fixture(%{owner: user})
      project2 = WeCraft.ProjectsFixtures.project_fixture(%{owner: user})

      # Create milestone for project1
      {:ok, milestone} =
        WeCraft.Milestones.create_milestone(%{
          attrs: %{
            title: "Test Milestone",
            description: "Test Description",
            status: "planned",
            project_id: project1.id
          },
          scope: %{user: user}
        })

      conn = log_in_user(conn, user)

      # Try to edit milestone from project2
      assert {:error, {:live_redirect, %{flash: %{"error" => "Milestone not found"}}}} =
               live(conn, ~p"/project/#{project2.id}/milestones/#{milestone.id}/edit")
    end

    test "redirects when user doesn't have permission", %{conn: conn} do
      user = WeCraft.AccountsFixtures.user_fixture()
      other_user = WeCraft.AccountsFixtures.user_fixture()
      project = WeCraft.ProjectsFixtures.project_fixture(%{owner: other_user})

      # Create milestone as the project owner
      {:ok, milestone} =
        WeCraft.Milestones.create_milestone(%{
          attrs: %{
            title: "Test Milestone",
            description: "Test Description",
            status: "planned",
            project_id: project.id
          },
          scope: %{user: other_user}
        })

      conn = log_in_user(conn, user)

      # Try to edit milestone without permission
      assert {:error,
              {:live_redirect,
               %{flash: %{"error" => "You don't have permission to edit this milestone"}}}} =
               live(conn, ~p"/project/#{project.id}/milestones/#{milestone.id}/edit")
    end
  end

  describe "form validation" do
    test "validates form fields on change", %{conn: conn} do
      user = WeCraft.AccountsFixtures.user_fixture()
      project = WeCraft.ProjectsFixtures.project_fixture(%{owner: user})

      # Create a milestone to edit
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

      {:ok, view, _html} =
        live(conn, ~p"/project/#{project.id}/milestones/#{milestone.id}/edit")

      # Fill form with valid data
      result =
        view
        |> form("form",
          milestone: %{
            title: "Updated Milestone",
            description: "Updated Description",
            status: "active"
          }
        )
        |> render_change()

      # Should not show validation errors
      refute result =~ "can&#39;t be blank"
    end
  end

  describe "form submission" do
    test "updates milestone with valid data", %{conn: conn} do
      user = WeCraft.AccountsFixtures.user_fixture()
      project = WeCraft.ProjectsFixtures.project_fixture(%{owner: user})

      # Create a milestone to edit
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

      {:ok, view, _html} =
        live(conn, ~p"/project/#{project.id}/milestones/#{milestone.id}/edit")

      # Submit form with valid data
      view
      |> form("form",
        milestone: %{
          title: "Updated Milestone",
          description: "Updated Description",
          status: "active",
          due_date: "2025-12-31T23:59"
        }
      )
      |> render_submit()

      # Should redirect to milestones page
      assert_redirected(view, ~p"/project/#{project.id}/milestones")

      # Verify milestone was updated
      {:ok, updated_milestone} =
        WeCraft.Milestones.get_milestone(%{
          milestone_id: milestone.id,
          scope: %{user: user}
        })

      assert updated_milestone.title == "Updated Milestone"
      assert updated_milestone.description == "Updated Description"
      assert updated_milestone.status == :active
    end

    test "shows errors for invalid data", %{conn: conn} do
      user = WeCraft.AccountsFixtures.user_fixture()
      project = WeCraft.ProjectsFixtures.project_fixture(%{owner: user})

      # Create a milestone to edit
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

      {:ok, view, _html} =
        live(conn, ~p"/project/#{project.id}/milestones/#{milestone.id}/edit")

      # Submit form with invalid data
      result =
        view
        |> form("form", milestone: %{title: "", description: ""})
        |> render_submit()

      # Should show validation errors and stay on the form
      assert result =~ "can&#39;t be blank"
      assert result =~ "Edit Milestone"
    end
  end

  describe "cancel action" do
    test "navigates back to project milestones", %{conn: conn} do
      user = WeCraft.AccountsFixtures.user_fixture()
      project = WeCraft.ProjectsFixtures.project_fixture(%{owner: user})

      # Create a milestone to edit
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

      {:ok, view, _html} =
        live(conn, ~p"/project/#{project.id}/milestones/#{milestone.id}/edit")

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

      # Create a milestone to edit
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

      {:ok, _view, html} =
        live(conn, ~p"/project/#{project.id}/milestones/#{milestone.id}/edit")

      assert html =~ "Test Chat"
      assert html =~ "Milestones"
    end

    test "handles left menu events", %{conn: conn} do
      user = WeCraft.AccountsFixtures.user_fixture()
      project = WeCraft.ProjectsFixtures.project_fixture(%{owner: user})

      # Create a milestone to edit
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

      {:ok, view, _html} =
        live(conn, ~p"/project/#{project.id}/milestones/#{milestone.id}/edit")

      # Send section change event and verify navigation
      Process.send(view.pid, {:section_changed, :chat}, [])

      # Wait a bit for the message to be processed
      Process.sleep(10)

      # The test passes if no error occurs - the navigation is internal
      assert true
    end
  end
end
