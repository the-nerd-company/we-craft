defmodule WeCraft.TicketsFixtures do
  @moduledoc """
  This module defines test helpers for tickets.
  """
  alias WeCraft.ProjectsFixtures
  alias WeCraft.Tickets.Infrastructure.Ecto.TicketRepositoryEcto
  alias WeCraft.Tickets.Ticket

  def ticket_fixture(attrs \\ %{}) do
    project = attrs[:project] || ProjectsFixtures.project_fixture()

    valid_attrs = %{
      title: Faker.Lorem.sentence(),
      description: Faker.Lorem.paragraph(),
      type: Enum.random(Ticket.get_customer_ticket_types()),
      status: Enum.random(Ticket.get_ticket_status()),
      priority: 1,
      project_id: project.id
    }

    {:ok, ticket} =
      TicketRepositoryEcto.create_ticket(Map.merge(valid_attrs, attrs))

    ticket
  end
end
