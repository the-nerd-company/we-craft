defmodule WeCraft.CRM.UseCases.ListProjectCustomersUseCaseTest do
  @moduledoc """
  Tests for the ListProjectCustomersUseCase.
  Ensures permission checks and correct listing of customers by project.
  """
  use WeCraft.DataCase, async: true
  import WeCraft.ProjectsFixtures
  import WeCraft.CRMFixtures

  alias WeCraft.CRM

  defp scope_for_project(project, user_id \\ nil) do
    user = %{id: user_id || project.owner_id}
    %WeCraft.Accounts.Scope{user: user}
  end

  test "returns :unauthorized if user is not project owner" do
    project = project_fixture()
    scope = scope_for_project(project, -1)

    assert {:error, :unauthorized} =
             CRM.list_customers(%{project: project, scope: scope})
  end

  test "lists customers if user is project owner" do
    project = project_fixture()
    scope = scope_for_project(project)
    customer1 = customer_fixture(%{project: project})
    customer2 = customer_fixture(%{project: project})

    assert {:ok, customers} =
             CRM.list_customers(%{project: project, scope: scope})

    assert Enum.any?(customers, &(&1.id == customer1.id))
    assert Enum.any?(customers, &(&1.id == customer2.id))
  end
end
