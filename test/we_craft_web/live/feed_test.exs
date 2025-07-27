defmodule WeCraftWeb.FeedTest do
  @moduledoc """
  Tests for the Feed LiveView.
  """
  use WeCraftWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import WeCraft.ProjectsFixtures

  alias WeCraft.Projects.Infrastructure.Ecto.ProjectEventsRepositoryEcto

  setup %{conn: conn} do
    %{conn: conn} = register_and_log_in_user(%{conn: conn})
    {:ok, %{conn: conn}}
  end

  describe "mount" do
    test "shows empty state when no events", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/feed")
      assert html =~ "No activity yet"
      assert html =~ "Auto-refresh active"
    end
  end

  describe "with events" do
    test "renders events and formatting", %{conn: conn} do
      project = project_fixture(%{title: "Awesome Project"})

      {:ok, _} =
        ProjectEventsRepositoryEcto.create_event(%{
          event_type: "project_created",
          project_id: project.id
        })

      {:ok, lv, html} = live(conn, ~p"/feed")

      assert html =~ "Activity Feed"
      assert html =~ "New Project Created"
      assert html =~ "Awesome Project"
      assert html =~ "View"

      # Trigger manual refresh (still should render same or updated content)
      html2 = render_click(element(lv, "button[phx-click=refresh_feed]"))
      assert html2 =~ "Activity Feed"
    end
  end

  describe "toggle auto-refresh" do
    test "toggles feed_active assign", %{conn: conn} do
      {:ok, lv, html} = live(conn, ~p"/feed")
      assert html =~ "Auto-refresh active"

      html_paused = render_click(element(lv, "button[phx-click=toggle_feed]"))
      assert html_paused =~ "Auto-refresh paused"

      html_resumed = render_click(element(lv, "button[phx-click=toggle_feed]"))
      assert html_resumed =~ "Auto-refresh active"
    end
  end
end
