defmodule WeCraftWeb.Projects.CRM.NewCustomerTest do
  @moduledoc """
  LiveView tests for creating a new customer.
  """
  use WeCraftWeb.ConnCase, async: true
  import Phoenix.LiveViewTest
  import WeCraft.ProjectsFixtures

  setup [:register_and_log_in_user]

  setup %{user: user, conn: conn} do
    project = project_fixture(%{owner: user})
    {:ok, %{conn: conn, project: project, user: user}}
  end

  test "mount renders form", %{conn: conn, project: project} do
    {:ok, _lv, html} = live(conn, ~p"/project/#{project.id}/customers/new")
    assert html =~ "Add Customer"
    assert html =~ "Name"
    assert html =~ "Email"
  end

  test "validation errors show when submitting invalid data", %{conn: conn, project: project} do
    {:ok, lv, _html} = live(conn, ~p"/project/#{project.id}/customers/new")

    html =
      lv
      |> element("form#customer-form")
      |> render_change(%{"customer" => %{"name" => "", "email" => "", "external_id" => ""}})

    # Error text is HTML-escaped (can&#39;t), so assert on escaped form
    assert html =~ "can&#39;t be blank"
  end
end
