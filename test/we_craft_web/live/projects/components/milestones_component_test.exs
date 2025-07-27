defmodule WeCraftWeb.Projects.Components.MilestonesComponentTest do
  @moduledoc """
  Tests for the MilestonesComponent.
  """
  use WeCraftWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import WeCraft.AccountsFixtures
  import WeCraft.ProjectsFixtures
  import WeCraft.MilestonesFixtures

  alias WeCraftWeb.Projects.Components.MilestonesComponent

  describe "render/1" do
    test "shows empty state when no milestones and owner can create" do
      owner = user_fixture()
      project = project_fixture(%{owner: owner, title: "Project X"})

      assigns = %{
        id: "milestones",
        project: project,
        current_scope: %{user: owner}
      }

      html = render_component(MilestonesComponent, assigns)

      assert html =~ "No milestones yet"
      assert html =~ "Create Your First Milestone"
      assert html =~ "/project/#{project.id}/milestones/new"
    end

    test "lists existing milestones with status badges" do
      owner = user_fixture()
      project = project_fixture(%{owner: owner})

      planned = milestone_fixture(%{project: project, status: :planned, title: "Planned M"})
      active = milestone_fixture(%{project: project, status: :active, title: "Active M"})
      completed = milestone_fixture(%{project: project, status: :completed, title: "Completed M"})

      assigns = %{
        id: "milestones",
        project: project,
        current_scope: %{user: owner}
      }

      html = render_component(MilestonesComponent, assigns)

      for t <- [planned.title, active.title, completed.title] do
        assert html =~ t
      end

      assert html =~ "Planned"
      assert html =~ "Active"
      assert html =~ "Completed"
    end

    test "non-owner cannot see new milestone button" do
      owner = user_fixture()
      other = user_fixture()
      project = project_fixture(%{owner: owner})

      _milestone = milestone_fixture(%{project: project, status: :active, title: "Active M"})

      assigns = %{
        id: "milestones",
        project: project,
        current_scope: %{user: other}
      }

      html = render_component(MilestonesComponent, assigns)

      refute html =~ "New Milestone"
      refute html =~ "Create Your First Milestone"
    end
  end
end
