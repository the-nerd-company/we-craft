defmodule WeCraft.Tickets.UseCases.DeleteTicketUseCaseTest do
  @moduledoc """
  Test suite for the DeleteTicketUseCase.
  """
  use WeCraft.DataCase, async: true

  alias WeCraft.Tickets
  alias WeCraft.Tickets.Infrastructure.Ecto.TicketRepositoryEcto

  import WeCraft.TicketsFixtures
  import WeCraft.ProjectsFixtures

  test "deletes a ticket" do
    project = project_fixture()
    ticket = ticket_fixture(%{project: project})

    {:ok, _} = Tickets.delete_ticket(ticket)
    assert TicketRepositoryEcto.get_ticket(ticket.id) == nil
  end
end
