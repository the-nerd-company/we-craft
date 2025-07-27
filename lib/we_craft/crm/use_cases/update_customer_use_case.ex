defmodule WeCraft.CRM.UseCases.UpdateCustomerUseCase do
  @moduledoc """
  Use case for creating a customer.
  """
  alias WeCraft.CRM.CRMPermissions
  alias WeCraft.CRM.Customer
  alias WeCraft.CRM.Infrastructure.Ecto.CustomerRepositoryEcto

  def update_customer(%{
        project: project,
        customer: %Customer{} = customer,
        attrs: attrs,
        scope: scope
      }) do
    if CRMPermissions.can_create_contact?(%{project: project, scope: scope}) do
      CustomerRepositoryEcto.update_customer(customer, attrs)
    else
      {:error, :unauthorized}
    end
  end
end
