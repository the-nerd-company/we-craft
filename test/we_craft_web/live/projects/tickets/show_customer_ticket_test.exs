defmodule WeCraftWeb.Projects.Tickets.ShowCustomerTicketTest do
  @moduledoc false
  use WeCraftWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import WeCraft.TicketsFixtures
  import WeCraft.ProjectsFixtures

  describe "show customer ticket liveview" do
    setup [:register_and_log_in_user]

    test "mount renders ticket details", %{conn: conn, scope: scope} do
      # Setup project owned by logged user to ensure permission success
      project = project_fixture(%{owner: scope.user})

      ticket =
        ticket_fixture(%{
          project: project,
          title: "Customer cannot login",
          priority: 3,
          status: :new,
          type: :bug_report
        })

      {:ok, view, html} = live(conn, ~p"/project/#{project.id}/tickets/#{ticket.id}")

      assert html =~ "Customer cannot login"
      # Type & status formatting
      assert html =~ "Bug Report"
      assert html =~ "New"
      assert html =~ "Priority: 3"
      assert has_element?(view, "a", "Back to tickets")
      assert view |> has_element?(~s|a[href="/project/#{project.id}/tickets"]|)
    end

    test "back link patches to tickets list", %{conn: conn, scope: scope} do
      project = project_fixture(%{owner: scope.user})
      ticket = ticket_fixture(%{project: project})

      {:ok, view, _html} = live(conn, ~p"/project/#{project.id}/tickets/#{ticket.id}")

      view |> element("a", "Back to tickets") |> render_click()
      assert_patch(view, ~p"/project/#{project.id}/tickets")
    end
  end
end
