defmodule WeCraft.Tickets.UseCases.UpdateTicketUseCaseTest do
  @moduledoc """
  Test suite for the UpdateTicketUseCase.
  """
  use WeCraft.DataCase, async: true

  alias WeCraft.Tickets

  import WeCraft.TicketsFixtures
  import WeCraft.ProjectsFixtures

  test "updates a ticket" do
    project = project_fixture()
    ticket = ticket_fixture(%{project: project})

    {:ok, updated} = Tickets.update_ticket(%{ticket: ticket, attrs: %{title: "Updated!"}})

    assert updated.title == "Updated!"
  end
end
