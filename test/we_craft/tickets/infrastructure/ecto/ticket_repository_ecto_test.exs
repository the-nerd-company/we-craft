defmodule WeCraft.Tickets.Infrastructure.Ecto.TicketRepositoryEctoTest do
  @moduledoc """
  Test suite for the TicketRepositoryEcto.
  """
  use WeCraft.DataCase, async: true
  alias WeCraft.Tickets.Infrastructure.Ecto.TicketRepositoryEcto
  import WeCraft.TicketsFixtures

  describe "TicketRepositoryEcto" do
    test "create, get, update, delete, and list tickets" do
      ticket = ticket_fixture(%{title: "Repo Test"})
      assert ticket.id
      found = TicketRepositoryEcto.get_ticket(ticket.id)
      assert found.id == ticket.id

      {:ok, updated} = TicketRepositoryEcto.update_ticket(ticket, %{title: "Updated"})
      assert updated.title == "Updated"

      {:ok, _} = TicketRepositoryEcto.delete_ticket(updated)
      assert TicketRepositoryEcto.get_ticket(ticket.id) == nil
    end
  end
end
