defmodule WeCraft.CRM.UseCases.UpdateCustomerUseCaseTest do
  @moduledoc """
  Tests for the UpdateCustomerUseCase.
  Ensures permission checks and update logic for CRM customers.
  """
  use WeCraft.DataCase, async: true
  import WeCraft.CRMFixtures

  alias WeCraft.CRM

  defp scope_for_project(project, user_id \\ nil) do
    user = %{id: user_id || project.owner_id}
    %WeCraft.Accounts.Scope{user: user}
  end

  test "returns :unauthorized if user is not project owner" do
    customer = customer_fixture()
    project = customer.project
    scope = scope_for_project(project, -1)

    assert {:error, :unauthorized} =
             CRM.update_customer(%{
               project: project,
               customer: customer,
               attrs: %{},
               scope: scope
             })
  end

  test "updates customer if user is project owner" do
    customer = customer_fixture()
    project = customer.project
    scope = scope_for_project(project)
    new_name = "Updated Name"

    assert {:ok, updated_customer} =
             CRM.update_customer(%{
               project: project,
               customer: customer,
               attrs: %{name: new_name},
               scope: scope
             })

    assert updated_customer.name == new_name
  end
end
