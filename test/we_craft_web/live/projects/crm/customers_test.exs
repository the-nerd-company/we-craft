defmodule WeCraftWeb.Projects.CRM.CustomersTest do
  @moduledoc """
  LiveView tests for the Customers listing page.
  """
  use WeCraftWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import WeCraft.ProjectsFixtures
  import WeCraft.CRMFixtures

  setup [:register_and_log_in_user]

  setup %{user: user, conn: conn} do
    project = project_fixture(%{owner: user})
    customer1 = customer_fixture(%{project: project, name: "Alice Test"})
    customer2 = customer_fixture(%{project: project, name: "Bob Sample"})

    %{conn: conn, project: project, customer1: customer1, customer2: customer2}
  end

  test "mount lists customers and shows Add Customer link", %{
    conn: conn,
    project: project,
    customer1: c1,
    customer2: c2
  } do
    {:ok, _lv, html} = live(conn, ~p"/project/#{project.id}/customers")

    assert html =~ "Customers"
    assert html =~ c1.name
    assert html =~ c2.name
    assert html =~ ~p"/project/#{project.id}/customers/new"
  end

  test "Details link present for each customer", %{conn: conn, project: project, customer1: c1} do
    {:ok, _lv, html} = live(conn, ~p"/project/#{project.id}/customers")
    assert html =~ ~p"/project/#{project.id}/customers/#{c1.id}/edit"
  end
end
