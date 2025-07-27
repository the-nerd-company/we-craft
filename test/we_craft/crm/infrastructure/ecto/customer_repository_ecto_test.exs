defmodule WeCraft.CRM.Infrastructure.Ecto.CustomerRepositoryEctoTest do
  @moduledoc """
  Tests for the Ecto-based customer repository.
  """
  use WeCraft.DataCase, async: true

  import WeCraft.CRMFixtures
  import WeCraft.ProjectsFixtures

  alias WeCraft.CRM.Customer
  alias WeCraft.CRM.Infrastructure.Ecto.CustomerRepositoryEcto

  describe "create_customer/1" do
    test "creates a customer with valid attributes" do
      project = project_fixture()

      attrs = %{
        email: "test@example.com",
        name: "Test Customer",
        external_id: "ext-123",
        project_id: project.id
      }

      assert {:ok, %Customer{} = customer} = CustomerRepositoryEcto.create_customer(attrs)
      assert customer.email == "test@example.com"
      assert customer.name == "Test Customer"
      assert customer.external_id == "ext-123"
      assert customer.project_id == project.id
    end

    test "returns error changeset with invalid attributes" do
      assert {:error, changeset} = CustomerRepositoryEcto.create_customer(%{})
      refute changeset.valid?
    end
  end

  describe "get_customer/1" do
    test "returns the customer by id" do
      customer = customer_fixture()
      customer_id = customer.id
      assert %Customer{id: ^customer_id} = CustomerRepositoryEcto.get_customer(customer_id)
    end

    test "returns nil if customer does not exist" do
      assert CustomerRepositoryEcto.get_customer(-1) == nil
    end
  end

  describe "update_customer/2" do
    test "updates the customer with valid data" do
      customer = customer_fixture()
      assert {:ok, updated} = CustomerRepositoryEcto.update_customer(customer, %{name: "Updated"})
      assert updated.name == "Updated"
    end

    test "returns error changeset with invalid data" do
      customer = customer_fixture()
      assert {:error, changeset} = CustomerRepositoryEcto.update_customer(customer, %{name: nil})
      refute changeset.valid?
    end
  end

  describe "delete_customer/1" do
    test "deletes the customer" do
      customer = customer_fixture()
      assert {:ok, %Customer{}} = CustomerRepositoryEcto.delete_customer(customer)
      assert CustomerRepositoryEcto.get_customer(customer.id) == nil
    end
  end

  describe "list_customers_by_project/1" do
    test "returns all customers for a project" do
      project = project_fixture()
      customer1 = customer_fixture(%{project_id: project.id, name: "A"})
      customer2 = customer_fixture(%{project_id: project.id, name: "B"})
      other_project = project_fixture()
      _other_customer = customer_fixture(%{project_id: other_project.id})

      customers = CustomerRepositoryEcto.list_customers_by_project(project.id)

      assert Enum.map(customers, & &1.id) |> Enum.sort() ==
               Enum.sort([customer1.id, customer2.id])

      assert Enum.all?(customers, &(&1.project_id == project.id))
    end
  end
end
