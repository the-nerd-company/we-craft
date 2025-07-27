defmodule WeCraft.Tickets.UseCases.UpdateTicketUseCase do
  @moduledoc """
  Use case for updating a ticket.
  """
  alias WeCraft.Tickets.Infrastructure.Ecto.TicketRepositoryEcto
  alias WeCraft.Tickets.Ticket

  def update_ticket(%{ticket: %Ticket{} = ticket, attrs: attrs}) do
    TicketRepositoryEcto.update_ticket(ticket, attrs)
  end
end
