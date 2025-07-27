defmodule WeCraft.CRM.Infrastructure.Ecto.CustomerRepositoryEcto do
  @moduledoc """
  Ecto-based implementation of the customer repository.
  """
  alias WeCraft.CRM.Customer
  alias WeCraft.Repo

  import Ecto.Query, warn: false

  def list_customers_by_project(project_id) do
    Repo.all(
      from c in Customer,
        where: c.project_id == ^project_id,
        order_by: [asc: c.name, desc: c.inserted_at]
    )
  end

  def get_customer(id), do: Repo.get(Customer, id) |> Repo.preload(:project)

  def create_customer(attrs) do
    %Customer{}
    |> Customer.changeset(attrs)
    |> Repo.insert()
  end

  def update_customer(%Customer{} = customer, attrs) do
    customer
    |> Customer.changeset(attrs)
    |> Repo.update()
  end

  def delete_customer(%Customer{} = customer) do
    Repo.delete(customer)
  end
end
