defmodule WeCraft.CRMFixtures do
  @moduledoc """
  Test fixtures for the CRM context.
  """
  alias WeCraft.CRM.Customer
  alias WeCraft.Repo

  import WeCraft.ProjectsFixtures

  def customer_fixture(attrs \\ %{}) do
    project = attrs[:project] || project_fixture()

    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(
        attrs
        |> Enum.into(%{
          email: Faker.Internet.email(),
          name: Faker.Person.name(),
          external_id: UUID.uuid4(),
          project_id: project.id
        })
      )
      |> Repo.insert()

    customer |> Repo.preload(:project)
  end
end
