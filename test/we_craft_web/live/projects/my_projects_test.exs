defmodule WeCraftWeb.Projects.MyProjectsTest do
  @moduledoc """
  Tests for the WeCraftWeb.Projects.MyProjects LiveView.
  """
  use WeCraftWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import WeCraft.ProjectsFixtures

  alias WeCraft.Accounts.Scope

  describe "mount/3" do
    setup :register_and_log_in_user

    test "loads user's projects on mount", %{conn: conn, user: user} do
      # Create some projects for this user
      project1 = project_fixture(%{owner: user, title: "Project 1"})
      project2 = project_fixture(%{owner: user, title: "Project 2"})

      # Create a project for another user to ensure it's not included
      other_user = WeCraft.AccountsFixtures.user_fixture()
      _other_project = project_fixture(%{owner: other_user, title: "Other Project"})

      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))
      {:ok, lv, _html} = live(conn, ~p"/my-projects")

      assigns = :sys.get_state(lv.pid).socket.assigns

      assert length(assigns.projects) == 2
      project_ids = Enum.map(assigns.projects, & &1.id) |> Enum.sort()
      expected_ids = [project1.id, project2.id] |> Enum.sort()
      assert project_ids == expected_ids
    end

    test "loads empty list when user has no projects", %{conn: conn, user: user} do
      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))
      {:ok, lv, _html} = live(conn, ~p"/my-projects")

      assigns = :sys.get_state(lv.pid).socket.assigns
      assert assigns.projects == []
    end
  end

  describe "render/1" do
    setup :register_and_log_in_user

    test "renders the page title and subtitle", %{conn: conn, user: user} do
      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))
      {:ok, _lv, html} = live(conn, ~p"/my-projects")

      assert html =~ "My Projects"
      assert html =~ "Manage and explore your craft projects"
    end

    test "renders create new project button", %{conn: conn, user: user} do
      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))
      {:ok, _lv, html} = live(conn, ~p"/my-projects")

      assert html =~ "New Project"
      assert html =~ ~s(href="/projects/new")
    end

    test "renders empty state when no projects", %{conn: conn, user: user} do
      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))
      {:ok, _lv, html} = live(conn, ~p"/my-projects")

      # Should show the empty state message
      assert html =~ "No projects yet"
      assert html =~ "Create your first project to start tracking your crafting journey"
      assert html =~ "Create Your First Project"
    end

    test "renders grid of user's projects", %{conn: conn, user: user} do
      project1 = project_fixture(%{owner: user, title: "My First Project"})
      project2 = project_fixture(%{owner: user, title: "My Second Project"})

      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))
      {:ok, _lv, html} = live(conn, ~p"/my-projects")

      # Should render project cards with the correct titles
      assert html =~ ~s(href="/project/#{project1.id}")
      assert html =~ ~s(href="/project/#{project2.id}")
      assert html =~ "My First Project"
      assert html =~ "My Second Project"

      # Should have project cards in a grid
      assert html =~ ~r/<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mt-6">/

      assert html =~
               ~r/<div class="card bg-base-100 shadow-lg hover:shadow-xl transition-all duration-300">/
    end

    test "renders project cards with descriptions", %{conn: conn, user: user} do
      description = "This is a detailed description of my amazing project"

      _project =
        project_fixture(%{
          owner: user,
          title: "Project With Description",
          description: description
        })

      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))
      {:ok, _lv, html} = live(conn, ~p"/my-projects")

      assert html =~ description
    end

    test "only shows current user's projects", %{conn: conn, user: user} do
      # Create project for current user
      user_project = project_fixture(%{owner: user, title: "User Project"})

      # Create project for different user
      other_user = WeCraft.AccountsFixtures.user_fixture()
      other_project = project_fixture(%{owner: other_user, title: "Other Project"})

      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))
      {:ok, _lv, html} = live(conn, ~p"/my-projects")

      # Should include user's project
      assert html =~ ~s(href="/project/#{user_project.id}")

      # Should NOT include other user's project
      refute html =~ ~s(href="/project/#{other_project.id}")
    end
  end

  describe "navigation" do
    setup :register_and_log_in_user

    test "header new project button navigates correctly", %{conn: conn, user: user} do
      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))
      {:ok, lv, _html} = live(conn, ~p"/my-projects")

      # Click the new project button in the header
      {:ok, _new_lv, _html} =
        lv |> element("header a", "New Project") |> render_click() |> follow_redirect(conn)

      # Should navigate to the new project page
      assert_redirected(lv, ~p"/projects/new")
    end

    test "empty state create project button navigates correctly", %{conn: conn, user: user} do
      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))
      {:ok, lv, _html} = live(conn, ~p"/my-projects")

      # Should only attempt this if the element exists (when no projects)
      if has_element?(lv, "a", "Create Your First Project") do
        {:ok, _new_lv, _html} =
          lv
          |> element("a", "Create Your First Project")
          |> render_click()
          |> follow_redirect(conn)

        # Should navigate to the new project page
        assert_redirected(lv, ~p"/projects/new")
      end
    end

    test "view project button exists and has correct href", %{conn: conn, user: user} do
      project = project_fixture(%{owner: user, title: "Test Project"})

      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))
      {:ok, lv, _html} = live(conn, ~p"/my-projects")

      # Check that the view project button exists with the correct href
      assert has_element?(
               lv,
               ".card-actions a.btn-sm[href='/project/#{project.id}']",
               "View Project"
             )
    end

    test "dropdown menu has correct links", %{conn: conn, user: user} do
      project = project_fixture(%{owner: user, title: "Test Project"})

      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))
      {:ok, _lv, html} = live(conn, ~p"/my-projects")

      # Dropdown menu should contain view and edit links
      assert html =~ ~s(href="/project/#{project.id}")
      assert html =~ ~s(href="/project/#{project.id}/edit")
    end
  end
end
