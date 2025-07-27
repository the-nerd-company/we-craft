defmodule WeCraft.CRM.UseCases.ListProjectCustomersUseCase do
  @moduledoc """
  Use case for listing customers by project.
  """
  alias WeCraft.CRM.CRMPermissions
  alias WeCraft.CRM.Infrastructure.Ecto.CustomerRepositoryEcto

  def list_customers(%{project: project, scope: scope}) do
    if CRMPermissions.can_view_contacts?(%{project: project, scope: scope}) do
      {:ok, CustomerRepositoryEcto.list_customers_by_project(project.id)}
    else
      {:error, :unauthorized}
    end
  end
end
