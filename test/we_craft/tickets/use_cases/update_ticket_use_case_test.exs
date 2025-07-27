defmodule WeCraft.Tickets.UseCases.UpdateTicketUseCaseTest do
  @moduledoc """
  Test suite for the UpdateTicketUseCase.
  """
  use WeCraft.DataCase, async: true

  alias WeCraft.Tickets.Infrastructure.Ecto.TicketRepositoryEcto
  alias WeCraft.Tickets.UseCases.UpdateTicketUseCase

  import WeCraft.TicketsFixtures
  import WeCraft.ProjectsFixtures

  test "updates a ticket" do
    project = project_fixture()
    ticket = ticket_fixture(%{project: project})

    {:ok, updated} =
      UpdateTicketUseCase.update_ticket(%{ticket: ticket, attrs: %{title: "Updated!"}})

    assert updated.title == "Updated!"
    TicketRepositoryEcto.delete_ticket(updated)
  end
end
