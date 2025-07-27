defmodule WeCraftWeb.Projects.Tickets.CustomersTicketTest do
  @moduledoc """
  Tests for the CustomersTicket LiveView (listing customer tickets).
  """
  use WeCraftWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import WeCraft.ProjectsFixtures
  import WeCraft.TicketsFixtures

  setup %{conn: conn} do
    # Authenticate user using helper (sets user_token in session)
    %{conn: conn, user: user, scope: scope} = register_and_log_in_user(%{conn: conn})
    project = project_fixture(%{owner: user})

    ticket1 =
      ticket_fixture(%{project: project, title: "Alpha Feature", status: :new, priority: 1})

    ticket2 =
      ticket_fixture(%{project: project, title: "Beta Bug", status: :in_progress, priority: 2})

    {:ok, %{conn: conn, project: project, tickets: [ticket1, ticket2], user: user, scope: scope}}
  end

  describe "mount/3" do
    test "lists tickets with headers and row data", %{
      conn: conn,
      project: project,
      tickets: tickets
    } do
      {:ok, _lv, html} = live(conn, "/project/#{project.id}/tickets")

      # Headers
      assert html =~ "Customer Tickets"
      assert html =~ "Title"
      assert html =~ "Type"
      assert html =~ "Status"
      assert html =~ "Priority"
      assert html =~ "Description"

      # Each seeded ticket title should appear
      for t <- tickets do
        assert html =~ t.title
        # Status badge class uses status_color mapping; assert one expected class appears
        # (We assert at least the formatted status text shows)
        formatted_status =
          t.status
          |> to_string()
          |> String.replace("_", " ")
          |> String.split()
          |> Enum.map_join(" ", &String.capitalize/1)

        assert html =~ formatted_status
      end

      # Details button link path present
      for t <- tickets do
        assert html =~ "/project/#{project.id}/tickets/#{t.id}"
      end
    end

    test "shows empty state when no tickets", %{conn: conn, user: user} do
      # New project owned by same authenticated user but with no tickets
      empty_project = project_fixture(%{owner: user})
      {:ok, _lv, html} = live(conn, "/project/#{empty_project.id}/tickets")

      # Should still render table headers
      assert html =~ "Customer Tickets"
      # No seeded ticket titles should appear
      refute html =~ "Alpha Feature"
      refute html =~ "Beta Bug"
    end
  end
end
