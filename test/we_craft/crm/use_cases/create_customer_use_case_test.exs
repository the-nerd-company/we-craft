defmodule WeCraft.CRM.UseCases.CreateCustomerUseCaseTest do
  @moduledoc """
  Tests for the CreateCustomerUseCase.
  This module tests the creation of a customer through the use case, ensuring that permissions are checked
  and that the customer is created correctly when the user has the necessary permissions.
  """
  use WeCraft.DataCase, async: true
  import WeCraft.ProjectsFixtures

  alias WeCraft.CRM

  defp scope_for_project(project, user_id \\ nil) do
    user = %{id: user_id || project.owner_id}
    %WeCraft.Accounts.Scope{user: user}
  end

  test "returns :unauthorized if user is not project owner" do
    project = project_fixture()
    scope = scope_for_project(project, -1)

    assert {:error, :unauthorized} =
             CRM.create_customer(%{project: project, attrs: %{}, scope: scope})
  end

  test "calls repo if user is project owner" do
    project = project_fixture()
    scope = scope_for_project(project)
    # Use the real repo (will hit the DB)
    assert {:ok, _customer} =
             CRM.create_customer(%{
               project: project,
               attrs: %{
                 name: Faker.Person.name(),
                 project_id: project.id,
                 email: Faker.Internet.email(),
                 external_id: Faker.UUID.v4()
               },
               scope: scope
             })
  end
end
