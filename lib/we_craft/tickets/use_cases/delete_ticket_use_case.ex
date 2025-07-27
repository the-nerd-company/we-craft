defmodule WeCraft.Tickets.UseCases.DeleteTicketUseCase do
  @moduledoc """
  Use case for deleting a ticket.
  """
  alias WeCraft.Tickets.Infrastructure.Ecto.TicketRepositoryEcto
  alias WeCraft.Tickets.Ticket

  def delete_ticket(%Ticket{} = ticket) do
    TicketRepositoryEcto.delete_ticket(ticket)
  end
end
