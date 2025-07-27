defmodule WeCraft.CRM.UseCases.DeleteCustomerUseCaseTest do
  @moduledoc """
  Tests for the DeleteCustomerUseCase.
  Ensures permission checks and correct deletion of customers.
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
             CRM.delete_customer(%{customer: customer, scope: scope})
  end

  test "deletes customer if user is project owner" do
    customer = customer_fixture()
    project = customer.project
    scope = scope_for_project(project)

    assert {:ok, _deleted_customer} =
             CRM.delete_customer(%{customer: customer, scope: scope})

    # Optionally, check that the customer is gone
    refute Repo.get_by(WeCraft.CRM.Customer, id: customer.id)
  end
end
