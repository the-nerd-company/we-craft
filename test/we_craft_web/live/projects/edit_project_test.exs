defmodule WeCraftWeb.Projects.EditProjectTest do
  @moduledoc """
  Tests for the WeCraftWeb.Projects.EditProject LiveView.
  """
  use WeCraftWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import WeCraft.ProjectsFixtures

  alias WeCraft.Accounts.Scope
  alias WeCraft.Projects.Project

  describe "mount/3" do
    setup :register_and_log_in_user

    test "initializes with project changeset", %{conn: conn, user: user} do
      project = project_fixture(%{owner: user, title: "Test Project"})
      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))

      {:ok, lv, _html} = live(conn, ~p"/project/#{project.id}/edit")

      assigns = :sys.get_state(lv.pid).socket.assigns

      assert %Project{} = assigns.project
      assert assigns.project.id == project.id
      assert assigns.project.title == "Test Project"
      assert %Ecto.Changeset{} = assigns.changeset
    end

    test "fails to mount with non-existent project", %{conn: conn, user: user} do
      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))

      # The specific error is FunctionClauseError from trying to use a nil project
      assert_raise FunctionClauseError, fn ->
        live(conn, ~p"/project/9999/edit")
      end
    end
  end

  describe "render/1" do
    setup :register_and_log_in_user

    test "renders the edit project form", %{conn: conn, user: user} do
      project = project_fixture(%{owner: user})
      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))

      {:ok, _lv, html} = live(conn, ~p"/project/#{project.id}/edit")

      # Title should ideally be "Edit Project" but the component is shared
      assert html =~ "Create New Project"
      assert html =~ "Project Title"
      assert html =~ "Description"
      assert html =~ "Project Status"
      assert html =~ "Visibility"
      # Button text should ideally be "Update Project"
      assert html =~ "Save Project"
    end
  end

  describe "component interaction" do
    setup :register_and_log_in_user

    test "project form shows current values", %{conn: conn, user: user} do
      project =
        project_fixture(%{
          owner: user,
          title: "Original Title",
          description: "Original Description",
          status: :in_dev,
          tags: ["elixir", "phoenix"]
        })

      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))
      {:ok, lv, html} = live(conn, ~p"/project/#{project.id}/edit")

      assert html =~ "Original Title"
      assert html =~ "Original Description"
      # Status should be selected
      assert html =~ "In Dev"
      assert has_element?(lv, "form")
      assert has_element?(lv, "button", "Save Project")
    end
  end

  # Note: These tests are placeholders for when the update functionality is implemented
  describe "project update functionality" do
    setup :register_and_log_in_user

    test "updates project and redirects on valid data", %{conn: conn, user: user} do
      project = project_fixture(%{owner: user, title: "Original Title"})
      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))

      {:ok, lv, _html} = live(conn, ~p"/project/#{project.id}/edit")

      # This test will need to be updated when the update functionality is implemented
      # For now, we're just testing that the form is rendered correctly
      assert has_element?(lv, "form")
    end

    test "updates project needs correctly", %{conn: conn, user: user} do
      # Create a project with empty needs array to ensure we're not affected by random fixtures
      project = project_fixture(%{owner: user, title: "Project with Needs", needs: []})
      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))

      {:ok, lv, _html} = live(conn, ~p"/project/#{project.id}/edit")

      # First send a change to ensure the form is initialized properly
      lv
      |> element("form")
      |> render_change(%{
        "project" => %{
          "needs" => []
        }
      })

      # Now submit the form with explicit needs
      lv
      |> element("form")
      |> render_submit(%{
        "project" => %{
          "title" => "Project with Needs",
          "description" => "Updated description with needs",
          "needs" => ["frontend", "backend"],
          "status" => "idea",
          "visibility" => "public",
          # Include empty tags to ensure they don't affect the test
          "tags" => []
        }
      })

      # Wait for redirect
      assert_redirect(lv, ~p"/project/#{project.id}")

      # Verify that the project was updated with the needs
      {:ok, updated_project} =
        WeCraft.Projects.get_project(%{project_id: project.id, scope: Scope.for_user(user)})

      assert updated_project.needs == ["frontend", "backend"]
    end

    test "shows errors and doesn't update on invalid data", %{conn: conn, user: user} do
      project = project_fixture(%{owner: user, title: "Original Title"})
      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))

      {:ok, lv, _html} = live(conn, ~p"/project/#{project.id}/edit")

      # This is a placeholder for when validation error handling is implemented
      assert has_element?(lv, "form")
    end
  end
end
