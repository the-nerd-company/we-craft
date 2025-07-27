defmodule WeCraftWeb.Projects.ProjectInfoTest do
  @moduledoc """
  Tests for the dedicated project info page.
  """
  use WeCraftWeb.ConnCase

  import Phoenix.LiveViewTest
  import WeCraft.AccountsFixtures
  import WeCraft.ProjectsFixtures
  import WeCraft.MilestonesFixtures

  alias WeCraft.Accounts.Scope

  describe "mount/3" do
    setup :register_and_log_in_user

    test "loads project and events successfully", %{conn: conn, user: user} do
      user = %{user | name: "Test User"}
      project = project_fixture(%{owner: user})

      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))
      {:ok, _lv, html} = live(conn, ~p"/project/#{project.id}/")

      assert html =~ "Project Information"
      assert html =~ project.title
    end

    test "loads project with active milestones", %{conn: conn, user: user} do
      user = %{user | name: "Test User"}
      project = project_fixture(%{owner: user})

      # Create some milestones with different statuses
      _active_milestone1 =
        milestone_fixture(%{project: project, status: :active, title: "Active Milestone 1"})

      _active_milestone2 =
        milestone_fixture(%{project: project, status: :active, title: "Active Milestone 2"})

      _planned_milestone =
        milestone_fixture(%{project: project, status: :planned, title: "Planned Milestone"})

      _completed_milestone =
        milestone_fixture(%{project: project, status: :completed, title: "Completed Milestone"})

      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))
      {:ok, _lv, html} = live(conn, ~p"/project/#{project.id}/")

      # Should show active milestones in both main content and left menu
      assert html =~ "Active Milestones"
      assert html =~ "Active Milestone 1"
      assert html =~ "Active Milestone 2"

      # Should not show non-active milestones in the main content
      refute html =~ "Planned Milestone"
      refute html =~ "Completed Milestone"

      # Should show active milestones in left menu under Milestones section
      assert html =~ "Active (2)"
      assert html =~ "Milestones"
    end

    test "does not show active milestones section when no active milestones exist", %{
      conn: conn,
      user: user
    } do
      user = %{user | name: "Test User"}
      project = project_fixture(%{owner: user})

      # Create only non-active milestones - explicitly set status
      _planned_milestone =
        milestone_fixture(%{project: project, status: :planned, title: "Planned Milestone"})

      _completed_milestone =
        milestone_fixture(%{project: project, status: :completed, title: "Completed Milestone"})

      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))
      {:ok, _lv, html} = live(conn, ~p"/project/#{project.id}/")

      # Should not show active milestones section (look for the actual section, not the comment)
      refute html =~ ~s(<.icon name="hero-flag" class="w-5 h-5" /> Active Milestones)
      refute html =~ "Planned Milestone"
      refute html =~ "Completed Milestone"
    end

    test "redirects when project not found", %{conn: conn, user: user} do
      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))

      # Should get an error redirect when project doesn't exist
      assert {:error, {:live_redirect, %{to: "/", flash: %{}}}} =
               live(conn, ~p"/project/99999")
    end
  end

  describe "render/1" do
    setup :register_and_log_in_user

    test "renders project details", %{conn: conn, user: user} do
      user = %{user | name: "Test User"}

      project =
        project_fixture(%{
          owner: user,
          title: "Awesome Project",
          description: "This is a test project description",
          tags: ["elixir", "phoenix"],
          needs: ["frontend", "devops"]
        })

      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))
      {:ok, _lv, html} = live(conn, ~p"/project/#{project.id}/")

      # Check that the project details are rendered correctly
      assert html =~ "Awesome Project"
      assert html =~ "This is a test project description"
      assert html =~ "elixir"
      assert html =~ "phoenix"
      assert html =~ "frontend"
      assert html =~ "devops"
      assert html =~ user.name || user.email
    end

    test "renders edit button for project owner", %{conn: conn, user: user} do
      user = %{user | name: "Test User"}
      project = project_fixture(%{owner: user})

      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))
      {:ok, _lv, html} = live(conn, ~p"/project/#{project.id}/")

      # Owner should see edit button
      assert html =~ ~s(href="/project/#{project.id}/edit")
    end

    test "does not render edit button for non-owner", %{conn: conn, user: user} do
      user = %{user | name: "Test User"}
      # Create a different user as project owner
      owner = user_fixture(%{name: "Project Owner"})
      project = project_fixture(%{owner: owner})

      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))
      {:ok, _lv, html} = live(conn, ~p"/project/#{project.id}/")

      # Non-owner should not see edit button
      refute html =~ ~s(href="/project/#{project.id}/edit")
    end

    test "renders project timeline with events", %{conn: conn, user: user} do
      user = %{user | name: "Test User"}
      project = project_fixture(%{owner: user})

      # Create some project events
      _event =
        %WeCraft.Projects.ProjectEvent{
          project_id: project.id,
          event_type: "Project Created",
          inserted_at: ~N[2023-01-01 00:00:00]
        }
        |> WeCraft.Repo.insert!()

      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))
      {:ok, _lv, html} = live(conn, ~p"/project/#{project.id}/")

      # Check that the timeline is rendered with the event
      assert html =~ "Project Timeline"
      assert html =~ "Project Created"
    end

    test "renders active milestone links", %{conn: conn, user: user} do
      user = %{user | name: "Test User"}
      project = project_fixture(%{owner: user})

      # Create an active milestone
      active_milestone =
        milestone_fixture(%{
          project: project,
          status: :active,
          title: "Clickable Milestone",
          description: "This milestone should be clickable"
        })

      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))
      {:ok, _lv, html} = live(conn, ~p"/project/#{project.id}/")

      # Should contain a link to the milestone edit page
      assert html =~ ~s(href="/project/#{project.id}/milestones/#{active_milestone.id}/edit")
      assert html =~ "Clickable Milestone"
      assert html =~ "This milestone should be clickable"
      assert html =~ "Active"
    end

    test "limits active milestones to 3 items", %{conn: conn, user: user} do
      user = %{user | name: "Test User"}
      project = project_fixture(%{owner: user})

      # Create 5 active milestones
      for i <- 1..5 do
        milestone_fixture(%{project: project, status: :active, title: "Active Milestone #{i}"})
      end

      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))
      {:ok, _lv, html} = live(conn, ~p"/project/#{project.id}/")

      # Should show first 3 milestones in main content (using badge to identify main content)
      assert html =~ ~s(<span class="badge badge-primary badge-xs">Active</span>)

      # Get the active milestones section content between "Active Milestones" header and next major section
      # The main content section will have "View All" link which left menu doesn't have
      assert html =~ "View All"

      # In main content, should show first 3 milestones (each has Active badge in main content)
      main_content_badges =
        Regex.scan(~r/<span class="badge badge-primary badge-xs">Active<\/span>/, html)

      assert length(main_content_badges) == 3

      # Should show "View All" link
      assert html =~ ~s(href="/project/#{project.id}/milestones")
    end

    test "shows due dates and overdue status for milestones", %{conn: conn, user: user} do
      user = %{user | name: "Test User"}
      project = project_fixture(%{owner: user})

      # Create an overdue milestone
      overdue_date = NaiveDateTime.add(NaiveDateTime.utc_now(), -7, :day)

      _overdue_milestone =
        milestone_fixture(%{
          project: project,
          status: :active,
          title: "Overdue Milestone",
          due_date: overdue_date
        })

      # Create a future milestone
      future_date = NaiveDateTime.add(NaiveDateTime.utc_now(), 7, :day)

      _future_milestone =
        milestone_fixture(%{
          project: project,
          status: :active,
          title: "Future Milestone",
          due_date: future_date
        })

      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))
      {:ok, _lv, html} = live(conn, ~p"/project/#{project.id}/")

      # Should show due dates
      assert html =~ "Due:"

      # Should show overdue status
      assert html =~ "(Overdue)"
    end
  end

  describe "handle_event/3 - toggle-follow" do
    setup :register_and_log_in_user

    test "toggles following state", %{conn: conn, user: user} do
      user = %{user | name: "Test User"}
      # Create a different user as project owner so current user can see action buttons
      owner = user_fixture(%{name: "Project Owner"})
      project = project_fixture(%{owner: owner})

      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))
      {:ok, lv, _html} = live(conn, ~p"/project/#{project.id}/")

      # Initially following should be false
      assigns = :sys.get_state(lv.pid).socket.assigns
      assert assigns.following == false

      # Toggle following
      lv |> element("button", "Follow Project") |> render_click()

      # Now following should be true and flash message should be shown
      assigns = :sys.get_state(lv.pid).socket.assigns
      assert assigns.following == true
      assert assigns.flash["info"] == "Now following this project!"

      # Toggle again to unfollow
      lv |> element("button", "Following") |> render_click()

      # Now following should be false again
      assigns = :sys.get_state(lv.pid).socket.assigns
      assert assigns.following == false
      assert assigns.flash["info"] == "Unfollowed project"
    end
  end

  describe "handle_event/3 - contact modal" do
    setup :register_and_log_in_user

    test "opens and closes contact modal", %{conn: conn, user: user} do
      user = %{user | name: "Test User"}
      # Create a different user as project owner so current user can see contact button
      owner = user_fixture(%{name: "Project Owner"})
      project = project_fixture(%{owner: owner})

      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))
      {:ok, lv, _html} = live(conn, ~p"/project/#{project.id}/")

      # Initially modal should be closed
      assigns = :sys.get_state(lv.pid).socket.assigns
      assert assigns.contact_modal_open == false

      # Open modal
      lv |> element("button", "Contact Owner") |> render_click()

      # Now modal should be open
      assigns = :sys.get_state(lv.pid).socket.assigns
      assert assigns.contact_modal_open == true

      # Close modal
      lv |> element("button", "Cancel") |> render_click()

      # Modal should be closed again
      assigns = :sys.get_state(lv.pid).socket.assigns
      assert assigns.contact_modal_open == false
    end
  end

  describe "left menu milestones integration" do
    setup :register_and_log_in_user

    test "displays milestones section in left menu", %{conn: conn, user: user} do
      user = %{user | name: "Test User"}
      project = project_fixture(%{owner: user})

      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))
      {:ok, _lv, html} = live(conn, ~p"/project/#{project.id}/")

      # Should show Milestones section in left menu
      assert html =~ "Milestones"
      assert html =~ "All milestones"
      assert html =~ ~s(href="/project/#{project.id}/milestones")
    end

    test "displays active milestones in left menu", %{conn: conn, user: user} do
      user = %{user | name: "Test User"}
      project = project_fixture(%{owner: user})

      # Create active milestones
      _active_milestone1 =
        milestone_fixture(%{project: project, status: :active, title: "Left Menu Milestone 1"})

      _active_milestone2 =
        milestone_fixture(%{project: project, status: :active, title: "Left Menu Milestone 2"})

      # Create non-active milestone
      _planned_milestone =
        milestone_fixture(%{project: project, status: :planned, title: "Planned Milestone"})

      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))
      {:ok, _lv, html} = live(conn, ~p"/project/#{project.id}/")

      # Should show active count in left menu
      assert html =~ "Active (2)"
      assert html =~ "Left Menu Milestone 1"
      assert html =~ "Left Menu Milestone 2"

      # Should not show planned milestone in active section
      refute html =~ "Planned Milestone"
    end

    test "limits active milestones to 5 in left menu", %{conn: conn, user: user} do
      user = %{user | name: "Test User"}
      project = project_fixture(%{owner: user})

      # Create 7 active milestones
      for i <- 1..7 do
        milestone_fixture(%{project: project, status: :active, title: "Left Menu Milestone #{i}"})
      end

      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))
      {:ok, _lv, html} = live(conn, ~p"/project/#{project.id}/")

      # Should show Active (7) count but only display first 5 milestones in left menu
      assert html =~ "Active (7)"
      assert html =~ "Left Menu Milestone 1"
      assert html =~ "Left Menu Milestone 5"

      # Should not show 6th and 7th milestones in left menu
      refute html =~ "Left Menu Milestone 6"
      refute html =~ "Left Menu Milestone 7"
    end

    test "shows due dates in left menu milestones", %{conn: conn, user: user} do
      user = %{user | name: "Test User"}
      project = project_fixture(%{owner: user})

      # Create an overdue milestone
      overdue_date = NaiveDateTime.add(NaiveDateTime.utc_now(), -2, :day)

      _overdue_milestone =
        milestone_fixture(%{
          project: project,
          status: :active,
          title: "Overdue Left Menu Milestone",
          due_date: overdue_date
        })

      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))
      {:ok, _lv, html} = live(conn, ~p"/project/#{project.id}/")

      # Should show due date and overdue indicator in left menu
      assert html =~ "Due:"
      assert html =~ "Overdue Left Menu Milestone"
    end

    test "milestone links in left menu navigate to edit page", %{conn: conn, user: user} do
      user = %{user | name: "Test User"}
      project = project_fixture(%{owner: user})

      active_milestone =
        milestone_fixture(%{
          project: project,
          status: :active,
          title: "Clickable Left Menu Milestone"
        })

      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))
      {:ok, _lv, html} = live(conn, ~p"/project/#{project.id}/")

      # Should contain link to milestone edit page in left menu
      assert html =~ ~s(href="/project/#{project.id}/milestones/#{active_milestone.id}/edit")
      assert html =~ "Clickable Left Menu Milestone"
    end

    test "shows new milestone link for project owners", %{conn: conn, user: user} do
      user = %{user | name: "Test User"}
      project = project_fixture(%{owner: user})

      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))
      {:ok, _lv, html} = live(conn, ~p"/project/#{project.id}/")

      # Owner should see "New milestone" link in left menu
      assert html =~ "New milestone"
      assert html =~ ~s(href="/project/#{project.id}/milestones/new")
    end

    test "does not show new milestone link for non-owners", %{conn: conn, user: user} do
      user = %{user | name: "Test User"}
      # Create a different user as project owner
      owner = user_fixture(%{name: "Project Owner"})
      project = project_fixture(%{owner: owner})

      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))
      {:ok, _lv, html} = live(conn, ~p"/project/#{project.id}/")

      # Non-owner should not see "New milestone" link
      refute html =~ "New milestone"
      refute html =~ ~s(href="/project/#{project.id}/milestones/new")
    end
  end
end
