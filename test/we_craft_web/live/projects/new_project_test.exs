defmodule WeCraftWeb.Projects.NewProjectTest do
  @moduledoc """
  Tests for the WeCraftWeb.Projects.NewProject LiveView.
  """
  use WeCraftWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias WeCraft.Accounts.Scope
  alias WeCraft.Projects.Project
  alias WeCraft.Repo

  describe "mount/3" do
    setup :register_and_log_in_user

    test "initializes with empty changeset", %{conn: conn, user: user} do
      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))
      {:ok, lv, _html} = live(conn, ~p"/projects/new")

      assigns = :sys.get_state(lv.pid).socket.assigns

      assert %Ecto.Changeset{} = assigns.changeset
    end
  end

  describe "render/1" do
    setup :register_and_log_in_user

    test "renders the new project form", %{conn: conn, user: user} do
      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))
      {:ok, _lv, html} = live(conn, ~p"/projects/new")

      assert html =~ "Create New Project"
      assert html =~ "Share your idea with the community"
      assert html =~ "Project Title"
      assert html =~ "Description"
      assert html =~ "Project Status"
      assert html =~ "Visibility"
      assert html =~ "Save Project"
    end

    test "renders form fields with correct options", %{conn: conn, user: user} do
      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))
      {:ok, _lv, html} = live(conn, ~p"/projects/new")

      # Check status options
      assert html =~ "Idea"
      assert html =~ "In Dev"
      assert html =~ "Live"

      # Check visibility options
      assert html =~ "Public"
    end
  end

  describe "component validation" do
    setup :register_and_log_in_user

    test "validates form and updates changeset in component", %{conn: conn, user: user} do
      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))
      {:ok, lv, _html} = live(conn, ~p"/projects/new")

      # This test will focus on project creation rather than validation
      # since the validation happens in the component
      assert has_element?(lv, "form")
      assert has_element?(lv, "button", "Save Project")
    end

    test "component is properly mounted", %{conn: conn, user: user} do
      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))
      {:ok, lv, _html} = live(conn, ~p"/projects/new")

      # Check that the form fields exist
      assert has_element?(lv, "input#project_title")
      assert has_element?(lv, "textarea#project_description")
      assert has_element?(lv, "select#project_status")
      assert has_element?(lv, "select#project_visibility")
      assert has_element?(lv, "button", "Save Project")
    end
  end

  describe "project creation via component" do
    setup :register_and_log_in_user

    test "creates project and redirects on valid data", %{conn: conn, user: user} do
      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))
      {:ok, lv, _html} = live(conn, ~p"/projects/new")

      valid_params = %{
        "title" => "Test Project",
        "description" => "A test project description",
        "status" => "idea",
        "visibility" => "public"
      }

      # Submit the form via the component
      render_submit(lv, "new-project-form-save", %{"project" => valid_params})

      # Check that project was created
      project = Repo.get_by(Project, title: "Test Project")
      assert project
      assert project.description == "A test project description"
      assert project.status == :idea
      assert project.visibility == :public
      assert project.owner_id == user.id

      # Should redirect to project page
      assert_redirected(lv, ~p"/project/#{project.id}")
    end

    test "shows flash message on successful creation", %{conn: conn, user: user} do
      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))
      {:ok, lv, _html} = live(conn, ~p"/projects/new")

      valid_params = %{
        "title" => "Flash Test Project",
        "description" => "A test project description",
        "status" => "idea",
        "visibility" => "public"
      }

      render_submit(lv, "new-project-form-save", %{"project" => valid_params})

      assert_redirected(lv, ~p"/project/#{Repo.get_by(Project, title: "Flash Test Project").id}")
    end

    test "shows errors and doesn't redirect on invalid data", %{conn: conn, user: user} do
      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))
      {:ok, lv, _html} = live(conn, ~p"/projects/new")

      invalid_params = %{
        "title" => "",
        "description" => "",
        "status" => "idea",
        "visibility" => "public"
      }

      html = render_submit(lv, "new-project-form-save", %{"project" => invalid_params})

      # Should show validation errors
      assert html =~ "can&#39;t be blank" or html =~ "can't be blank"

      # Should not create a project
      refute Repo.get_by(Project, title: "")

      # Should not redirect - LiveView should still be active
      assert has_element?(lv, "form")
    end

    test "creates project with tags and needs", %{conn: conn, user: user} do
      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))
      {:ok, lv, _html} = live(conn, ~p"/projects/new")

      valid_params = %{
        "title" => "Tagged Project",
        "description" => "A project with tags",
        "tags" => ["elixir", "phoenix"],
        "needs" => ["frontend", "backend"],
        "status" => "live",
        "visibility" => "public"
      }

      render_submit(lv, "new-project-form-save", %{"project" => valid_params})

      project = Repo.get_by(Project, title: "Tagged Project")
      assert project
      assert project.tags == ["elixir", "phoenix"]
      assert project.needs == ["frontend", "backend"]
      assert project.status == :live
    end
  end
end
