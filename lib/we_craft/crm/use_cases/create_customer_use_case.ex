defmodule WeCraft.CRM.UseCases.CreateCustomerUseCase do
  @moduledoc """
  Use case for creating a customer.
  """
  alias WeCraft.CRM.CRMPermissions
  alias WeCraft.CRM.Infrastructure.Ecto.CustomerRepositoryEcto
  alias WeCraft.Projects.Project

  def create_customer(%{project: %Project{} = project, attrs: attrs, scope: scope}) do
    if CRMPermissions.can_create_contact?(%{project: project, scope: scope}) do
      CustomerRepositoryEcto.create_customer(attrs)
    else
      {:error, :unauthorized}
    end
  end
end
