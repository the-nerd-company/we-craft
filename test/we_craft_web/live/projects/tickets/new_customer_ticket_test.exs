defmodule WeCraftWeb.Projects.Tickets.NewCustomerTicketTest do
  @moduledoc """
  Tests for the NewCustomerTicket LiveView.
  """
  use WeCraftWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import WeCraft.AccountsFixtures
  import WeCraft.ProjectsFixtures

  setup %{conn: conn} do
    user = user_fixture()
    scope = user_scope_fixture(user)
    project = project_fixture(%{owner: user})

    # Simulate user session assigns (current_scope is needed by mount)
    conn =
      conn
      |> init_test_session(%{})
      |> Plug.Conn.put_session(:user_scope, scope)

    {:ok, %{conn: conn, project: project, scope: scope, user: user}}
  end

  describe "mount" do
    test "loads project and renders form", %{conn: conn, project: project} do
      {:ok, _lv, html} = live(conn, "/project/#{project.id}/tickets/new")
      assert html =~ "Add Ticket"
      assert html =~ "ticket-form"
    end
  end

  describe "create ticket" do
    test "successfully creates a ticket and redirects", %{conn: conn, project: project} do
      {:ok, lv, _html} = live(conn, "/project/#{project.id}/tickets/new")

      form_data = %{
        "ticket" => %{
          "title" => "New Feature",
          "description" => "Add new feature X",
          "type" => to_string(:feature_request),
          "status" => to_string(:new),
          "priority" => "1"
        }
      }

      lv
      |> form("#ticket-form", form_data)
      |> render_submit()

      # After successful creation we navigate to tickets list
      assert_redirect(lv, "/project/#{project.id}/tickets")
    end

    test "shows errors on invalid submission", %{conn: conn, project: project} do
      {:ok, lv, _html} = live(conn, "/project/#{project.id}/tickets/new")

      # Missing required fields
      form_data = %{
        "ticket" => %{
          "title" => "",
          "description" => "",
          # Provide valid enum values so the test layer doesn't raise ArgumentError
          # while we still trigger errors for blank required fields (title, description, priority)
          "type" => to_string(:feature_request),
          "status" => to_string(:new),
          "priority" => ""
        }
      }

      html =
        lv
        |> form("#ticket-form", form_data)
        |> render_change()

      # We expect validation errors to appear (Changeset action set to :validate by component)
      # The apostrophe is HTML-escaped in the rendered markup (can&#39;t)
      assert html =~ "can&#39;t be blank"
    end
  end
end
