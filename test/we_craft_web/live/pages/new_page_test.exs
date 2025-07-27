defmodule WeCraftWeb.Pages.NewPageTest do
  @moduledoc """
  Tests for the NewPage LiveView.
  """
  use WeCraftWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import WeCraft.ProjectsFixtures

  alias WeCraft.Pages.Page
  alias WeCraft.Repo

  setup %{conn: conn} do
    %{conn: conn, user: user} = register_and_log_in_user(%{conn: conn})
    project = project_fixture(%{owner: user})
    {:ok, %{conn: conn, project: project, user: user}}
  end

  describe "mount" do
    test "renders form with disabled submit when empty", %{conn: conn, project: project} do
      {:ok, _lv, html} = live(conn, ~p"/project/#{project.id}/pages/new")

      assert html =~ "Create Page"
      # Button renders as disabled="" (boolean attr). Accept either form.
      assert html =~ ~s(disabled="")
    end
  end

  describe "validation" do
    test "shows errors on invalid submission", %{conn: conn, project: project} do
      {:ok, lv, _html} = live(conn, ~p"/project/#{project.id}/pages/new")

      lv
      |> form("#new-milestone-form", page: %{title: ""})
      |> render_change()
      |> then(fn html -> assert html =~ "can&#39;t be blank" end)
    end
  end

  describe "save" do
    test "creates page and redirects on valid data", %{conn: conn, project: project} do
      {:ok, lv, _html} = live(conn, ~p"/project/#{project.id}/pages/new")

      title = "Getting Started"

      lv
      |> form("#new-milestone-form", page: %{title: title})
      |> render_change()
      |> then(fn html -> refute html =~ "can&#39;t be blank" end)

      lv
      |> form("#new-milestone-form", page: %{title: title})
      |> render_submit()

      slug = Slug.slugify(title)
      page = Repo.get_by!(Page, slug: slug, project_id: project.id)

      # Redirect uses page id
      assert_redirect(lv, ~p"/project/#{project.id}/pages/#{page.id}")
      assert page.title == title
    end
  end
end
