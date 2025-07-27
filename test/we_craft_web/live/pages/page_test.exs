defmodule WeCraftWeb.Pages.PageTest do
  @moduledoc """
  Tests for the Page LiveView.
  This module tests the rendering and functionality of the page liveview.
  """
  use WeCraftWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import WeCraft.ProjectsFixtures
  import WeCraft.PagesFixtures

  describe "page liveview" do
    setup [:register_and_log_in_user]

    test "renders page title and allows editing", %{conn: conn, user: user} do
      project = project_fixture(%{owner: user})
      page = page_fixture(%{project: project, title: "Initial Title"})
      {:ok, view, _html} = live(conn, ~p"/project/#{project.id}/pages/#{page.id}")

      # Title is rendered
      assert has_element?(view, "input[name=title][value='Initial Title']")

      # Edit title
      new_title = "Updated Title"

      view
      |> element("input[name=title]")
      |> render_blur(%{"value" => new_title})

      # Title is updated in the input
      assert has_element?(view, "input[name=title][value='Updated Title']")
    end

    test "editor block is present", %{conn: conn, user: user} do
      project = project_fixture(%{owner: user})
      page = page_fixture(%{project: project})
      {:ok, view, _html} = live(conn, ~p"/project/#{project.id}/pages/#{page.id}")
      assert has_element?(view, "#editor")
    end
  end
end
