defmodule WeCraft.Tickets.UseCases.ListProjectTicketsUseCaseTest do
  @moduledoc """
  Test suite for the ListProjectTicketsUseCase.
  """
  use WeCraft.DataCase, async: true

  alias WeCraft.Tickets
  alias WeCraft.Tickets.Infrastructure.Ecto.TicketRepositoryEcto

  import WeCraft.TicketsFixtures
  import WeCraft.ProjectsFixtures

  test "lists tickets for a project" do
    project = project_fixture()
    ticket = ticket_fixture(%{project: project})

    {:ok, tickets} = Tickets.list_tickets(%{project: project})
    assert Enum.any?(tickets, &(&1.id == ticket.id))
    TicketRepositoryEcto.delete_ticket(ticket)
  end
end
