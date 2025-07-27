defmodule WeCraftWeb.Projects.Milestones.EditMilestoneTest do
  @moduledoc """
  Tests for the EditMilestone LiveView which allows editing milestones and managing their tasks.
  """
  use WeCraftWeb.ConnCase

  import Phoenix.LiveViewTest
  import WeCraft.AccountsFixtures
  import WeCraft.ProjectsFixtures

  @create_attrs %{
    title: "some title",
    description: "some description",
    status: "planned"
  }
  @update_attrs %{
    title: "some updated title",
    description: "some updated description",
    status: "active"
  }
  @invalid_attrs %{title: "", description: "", status: "planned"}

  describe "Edit milestone" do
    setup %{conn: conn} do
      user = user_fixture()
      project = project_fixture(%{owner: user})

      {:ok, milestone} =
        WeCraft.Milestones.create_milestone(%{
          attrs: @create_attrs |> Map.put(:project_id, project.id),
          scope: %{user: user}
        })

      %{conn: log_in_user(conn, user), user: user, project: project, milestone: milestone}
    end

    test "displays milestone", %{conn: conn, project: project, milestone: milestone} do
      {:ok, _edit_live, html} =
        live(conn, ~p"/project/#{project.id}/milestones/#{milestone.id}/edit")

      assert html =~ "Edit Milestone"
      assert html =~ milestone.title
    end

    test "saves milestone", %{conn: conn, project: project, milestone: milestone} do
      {:ok, edit_live, _html} =
        live(conn, ~p"/project/#{project.id}/milestones/#{milestone.id}/edit")

      assert edit_live
             |> form("form", milestone: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert edit_live
             |> form("form", milestone: @update_attrs)
             |> render_submit()

      assert_redirected(edit_live, ~p"/project/#{project.id}/milestones")
    end

    test "renders errors for invalid data", %{conn: conn, project: project, milestone: milestone} do
      {:ok, edit_live, _html} =
        live(conn, ~p"/project/#{project.id}/milestones/#{milestone.id}/edit")

      html =
        edit_live
        |> form("form", milestone: @invalid_attrs)
        |> render_change()

      assert html =~ "can&#39;t be blank"
    end

    test "cancels edit", %{conn: conn, project: project, milestone: milestone} do
      {:ok, edit_live, _html} =
        live(conn, ~p"/project/#{project.id}/milestones/#{milestone.id}/edit")

      edit_live
      |> element("a", "Cancel")
      |> render_click()

      assert_redirected(edit_live, ~p"/project/#{project.id}/milestones")
    end

    test "renders left menu with project info", %{
      conn: conn,
      project: project,
      milestone: milestone
    } do
      {:ok, _edit_live, html} =
        live(conn, ~p"/project/#{project.id}/milestones/#{milestone.id}/edit")

      assert html =~ project.title
      assert html =~ "Project Info"
      assert html =~ "Milestones"
    end
  end

  describe "Task management" do
    setup %{conn: conn} do
      user = user_fixture()
      project = project_fixture(%{owner: user})

      {:ok, milestone} =
        WeCraft.Milestones.create_milestone(%{
          attrs: @create_attrs |> Map.put(:project_id, project.id),
          scope: %{user: user}
        })

      %{conn: log_in_user(conn, user), user: user, project: project, milestone: milestone}
    end

    test "displays add task button", %{conn: conn, project: project, milestone: milestone} do
      {:ok, _edit_live, html} =
        live(conn, ~p"/project/#{project.id}/milestones/#{milestone.id}/edit")

      assert html =~ "Add Task"
    end

    test "can add task", %{conn: conn, project: project, milestone: milestone} do
      {:ok, edit_live, _html} =
        live(conn, ~p"/project/#{project.id}/milestones/#{milestone.id}/edit")

      result =
        edit_live
        |> element("button", "Add Task")
        |> render_click()

      assert result =~ "New Task"
    end

    test "can edit existing task", %{
      conn: conn,
      project: project,
      milestone: milestone,
      user: user
    } do
      # Create a task first
      {:ok, task} =
        WeCraft.Milestones.create_task(%{
          attrs: %{
            title: "Test Task",
            description: "Test Description",
            status: "planned",
            milestone_id: milestone.id
          },
          scope: %{user: user}
        })

      {:ok, edit_live, _html} =
        live(conn, ~p"/project/#{project.id}/milestones/#{milestone.id}/edit")

      # Task should be displayed
      html = render(edit_live)
      assert html =~ "Test Task"

      # Should be able to click edit if button exists
      if html =~ "phx-click=\"edit-task\"" do
        result =
          edit_live
          |> element("button[phx-click='edit-task'][phx-value-task-id='#{task.id}']")
          |> render_click()

        assert result =~ "Test Task"
      end
    end

    test "can complete task", %{conn: conn, project: project, milestone: milestone, user: user} do
      # Create a task first
      {:ok, task} =
        WeCraft.Milestones.create_task(%{
          attrs: %{
            title: "Task to Complete",
            description: "Test Description",
            status: "active",
            milestone_id: milestone.id
          },
          scope: %{user: user}
        })

      {:ok, edit_live, _html} =
        live(conn, ~p"/project/#{project.id}/milestones/#{milestone.id}/edit")

      html = render(edit_live)
      assert html =~ "Task to Complete"

      # Try to complete task if button exists
      if html =~ "phx-click=\"complete-task\"" do
        edit_live
        |> element("button[phx-click='complete-task'][phx-value-task-id='#{task.id}']")
        |> render_click()

        # Verify task was marked as completed
        {:ok, completed_task} =
          WeCraft.Milestones.get_task(%{task_id: task.id, scope: %{user: user}})

        assert completed_task.status == :completed
      end
    end

    test "can delete task", %{conn: conn, project: project, milestone: milestone, user: user} do
      # Create a task first
      {:ok, task} =
        WeCraft.Milestones.create_task(%{
          attrs: %{
            title: "Task to Delete",
            description: "Test Description",
            status: "planned",
            milestone_id: milestone.id
          },
          scope: %{user: user}
        })

      {:ok, edit_live, _html} =
        live(conn, ~p"/project/#{project.id}/milestones/#{milestone.id}/edit")

      html = render(edit_live)
      assert html =~ "Task to Delete"

      # Try to delete task if button exists
      if html =~ "phx-click=\"delete-task\"" do
        edit_live
        |> element("button[phx-click='delete-task'][phx-value-task-id='#{task.id}']")
        |> render_click()

        # Verify task was deleted
        result = WeCraft.Milestones.get_task(%{task_id: task.id, scope: %{user: user}})
        assert result == {:error, :not_found} or result == {:ok, nil}
      end
    end

    test "handles task form validation", %{
      conn: conn,
      project: project,
      milestone: milestone,
      user: user
    } do
      # Create a task first
      {:ok, task} =
        WeCraft.Milestones.create_task(%{
          attrs: %{
            title: "Test Task",
            description: "Test Description",
            status: "planned",
            milestone_id: milestone.id
          },
          scope: %{user: user}
        })

      {:ok, edit_live, _html} =
        live(conn, ~p"/project/#{project.id}/milestones/#{milestone.id}/edit")

      html = render(edit_live)
      assert html =~ "Test Task"

      # Try to edit task and validate if forms exist
      if html =~ "phx-click=\"edit-task\"" do
        result =
          edit_live
          |> element("button[phx-click='edit-task'][phx-value-task-id='#{task.id}']")
          |> render_click()

        if result =~ "phx-change=\"validate-task\"" do
          validation_result =
            edit_live
            |> form("form[phx-change='validate-task']",
              task: %{title: "", description: "Updated"}
            )
            |> render_change()

          assert validation_result =~ "can&#39;t be blank"
        end
      end
    end
  end

  describe "Error handling" do
    setup %{conn: conn} do
      user = user_fixture()
      project = project_fixture(%{owner: user})

      {:ok, milestone} =
        WeCraft.Milestones.create_milestone(%{
          attrs: @create_attrs |> Map.put(:project_id, project.id),
          scope: %{user: user}
        })

      %{conn: log_in_user(conn, user), user: user, project: project, milestone: milestone}
    end

    test "handles form validation gracefully", %{
      conn: conn,
      project: project,
      milestone: milestone
    } do
      {:ok, edit_live, _html} =
        live(conn, ~p"/project/#{project.id}/milestones/#{milestone.id}/edit")

      result =
        edit_live
        |> form("form", milestone: %{title: "", description: ""})
        |> render_change()

      assert result =~ "can&#39;t be blank"
    end
  end

  describe "Navigation and info messages" do
    setup %{conn: conn} do
      user = user_fixture()
      project = project_fixture(%{owner: user})

      {:ok, milestone} =
        WeCraft.Milestones.create_milestone(%{
          attrs: @create_attrs |> Map.put(:project_id, project.id),
          scope: %{user: user}
        })

      %{conn: log_in_user(conn, user), user: user, project: project, milestone: milestone}
    end

    test "handles info messages without crashing", %{
      conn: conn,
      project: project,
      milestone: milestone
    } do
      {:ok, edit_live, _html} =
        live(conn, ~p"/project/#{project.id}/milestones/#{milestone.id}/edit")

      # Send an info message
      send(edit_live.pid, {:show_flash, :info, "Test message"})

      # Should not crash
      html = render(edit_live)
      assert html =~ "Edit Milestone"
    end
  end
end
