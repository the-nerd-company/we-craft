defmodule WeCraftWeb.Projects.CRM.EditCustomerTest do
  @moduledoc false
  use WeCraftWeb.ConnCase, async: true
  import Phoenix.LiveViewTest
  import WeCraft.ProjectsFixtures
  import WeCraft.CRMFixtures

  setup [:register_and_log_in_user]

  setup %{user: user, conn: conn} do
    project = project_fixture(%{owner: user})

    customer =
      customer_fixture(%{project: project, name: "Original Name", email: "orig@example.com"})

    {:ok, %{conn: conn, project: project, customer: customer}}
  end

  test "mount shows Edit Customer form with existing data", %{
    conn: conn,
    project: project,
    customer: customer
  } do
    {:ok, _lv, html} = live(conn, ~p"/project/#{project.id}/customers/#{customer.id}/edit")
    assert html =~ "Edit Customer"
    assert html =~ customer.name
    assert html =~ customer.email
  end

  test "validation error on empty required fields", %{
    conn: conn,
    project: project,
    customer: customer
  } do
    {:ok, lv, _html} = live(conn, ~p"/project/#{project.id}/customers/#{customer.id}/edit")

    html =
      lv
      |> element("form#customer-form")
      |> render_change(%{"customer" => %{"name" => "", "email" => "", "external_id" => ""}})

    assert html =~ "can&#39;t be blank"
  end
end
