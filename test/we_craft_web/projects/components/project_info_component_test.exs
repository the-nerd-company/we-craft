defmodule WeCraftWeb.Projects.Components.ProjectInfoComponentTest do
  @moduledoc """
  Tests for the ProjectInfoComponent.
  """
  use WeCraftWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import WeCraft.AccountsFixtures
  import WeCraft.ProjectsFixtures

  alias WeCraft.Repo
  alias WeCraftWeb.Projects.Components.ProjectInfoComponent

  describe "render" do
    test "displays project information" do
      user = user_fixture()
      owner = user_fixture(name: "Project Owner", title: "Founder")

      project =
        project_fixture(%{
          owner: owner,
          title: "Test Project",
          description: "A test project description",
          status: :idea,
          needs: ["frontend", "backend"]
        })

      project = Repo.preload(project, :owner)

      assigns = %{
        project: project,
        current_user: user,
        current_scope: %{user: user},
        events: [],
        following: false,
        followers_count: 0,
        contact_modal_open: false
      }

      html = render_component(ProjectInfoComponent, assigns)

      # Test basic project information
      assert html =~ "Test Project"
      assert html =~ "A test project description"
      assert html =~ "Project Owner"

      # Test project needs
      assert html =~ "frontend"
      assert html =~ "backend"

      # Test status
      assert html =~ "Idea"
      assert html =~ "0 followers"
    end

    test "displays follower count correctly" do
      user = user_fixture()
      owner = user_fixture(name: "Project Owner")
      project = project_fixture(%{owner: owner, title: "Test Project"})
      project = Repo.preload(project, :owner)

      assigns = %{
        project: project,
        current_user: user,
        current_scope: %{user: user},
        events: [],
        following: false,
        followers_count: 5,
        contact_modal_open: false
      }

      html = render_component(ProjectInfoComponent, assigns)

      assert html =~ "5 followers"

      # Test action buttons (should show contact and follow buttons for non-owners)
      assert html =~ "Contact"
      assert html =~ "Follow Project"
    end

    test "shows edit button for project owner" do
      owner = user_fixture(name: "Project Owner")
      project = project_fixture(%{owner: owner, title: "My Project"})
      project = Repo.preload(project, :owner)

      assigns = %{
        project: project,
        current_user: owner,
        current_scope: %{user: owner},
        events: [],
        following: false,
        followers_count: 0,
        contact_modal_open: false
      }

      html = render_component(ProjectInfoComponent, assigns)

      # Owner should see edit button instead of contact/follow
      assert html =~ "Edit"
      refute html =~ "Contact"
      refute html =~ "Follow"
    end

    test "shows unfollow button when user is following" do
      user = user_fixture()
      owner = user_fixture(name: "Project Owner")
      project = project_fixture(%{owner: owner, title: "Test Project"})
      project = Repo.preload(project, :owner)

      assigns = %{
        project: project,
        current_user: user,
        current_scope: %{user: user},
        events: [],
        following: true,
        followers_count: 1,
        contact_modal_open: false
      }

      html = render_component(ProjectInfoComponent, assigns)

      # Should show following button when already following
      assert html =~ "Following"
      refute html =~ "Follow Project"
    end

    test "handles empty needs list" do
      user = user_fixture()
      owner = user_fixture(name: "Project Owner")

      project =
        project_fixture(%{
          owner: owner,
          title: "Self-sufficient Project",
          needs: []
        })

      project = Repo.preload(project, :owner)

      assigns = %{
        project: project,
        current_user: user,
        current_scope: %{user: user},
        events: [],
        following: false,
        followers_count: 0,
        contact_modal_open: false
      }

      html = render_component(ProjectInfoComponent, assigns)

      # Should still render without errors
      assert html =~ "Self-sufficient Project"
      assert html =~ "Project Owner"
    end
  end

  describe "event handling" do
    test "component renders with proper event attributes" do
      user = user_fixture()
      owner = user_fixture()
      project = project_fixture(%{owner: owner})
      project = Repo.preload(project, :owner)

      assigns = %{
        project: project,
        current_user: user,
        current_scope: %{user: user},
        events: [],
        following: false,
        followers_count: 0,
        contact_modal_open: false
      }

      html = render_component(ProjectInfoComponent, assigns)

      # Check that buttons have proper phx-click attributes
      assert html =~ ~s(phx-click="toggle-follow")
      assert html =~ ~s(phx-click="open-contact-modal")
    end

    test "shows correct event attributes when following" do
      user = user_fixture()
      owner = user_fixture()
      project = project_fixture(%{owner: owner})
      project = Repo.preload(project, :owner)

      assigns = %{
        project: project,
        current_user: user,
        current_scope: %{user: user},
        events: [],
        following: true,
        followers_count: 1,
        contact_modal_open: false
      }

      html = render_component(ProjectInfoComponent, assigns)

      # Should show correct following state
      assert html =~ "Following"
    end

    test "shows edit event for project owner" do
      owner = user_fixture()
      project = project_fixture(%{owner: owner})
      project = Repo.preload(project, :owner)

      assigns = %{
        project: project,
        current_user: owner,
        current_scope: %{user: owner},
        events: [],
        following: false,
        followers_count: 0,
        contact_modal_open: false
      }

      html = render_component(ProjectInfoComponent, assigns)

      # Owner should see edit button
      assert html =~ "Edit"
    end
  end
end
