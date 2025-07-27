defmodule WeCraft.CRM do
  @moduledoc """
  A module for managing customer relationships.
  """

  defdelegate create_customer(params), to: WeCraft.CRM.UseCases.CreateCustomerUseCase

  defdelegate list_customers(params), to: WeCraft.CRM.UseCases.ListProjectCustomersUseCase

  defdelegate update_customer(params), to: WeCraft.CRM.UseCases.UpdateCustomerUseCase

  defdelegate delete_customer(params), to: WeCraft.CRM.UseCases.DeleteCustomerUseCase
end
