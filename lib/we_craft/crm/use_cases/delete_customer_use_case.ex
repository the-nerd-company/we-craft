defmodule WeCraft.CRM.UseCases.DeleteCustomerUseCase do
  @moduledoc """
  Use case for deleting a customer.
  """
  alias WeCraft.CRM.CRMPermissions
  alias WeCraft.CRM.Infrastructure.Ecto.CustomerRepositoryEcto

  def delete_customer(%{customer: customer, scope: scope}) do
    if CRMPermissions.can_create_contact?(%{project: customer.project, scope: scope}) do
      CustomerRepositoryEcto.delete_customer(customer)
    else
      {:error, :unauthorized}
    end
  end
end
