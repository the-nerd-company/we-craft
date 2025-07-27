defmodule WeCraft.Tickets.UseCases.GetTicketUseCase do
  @moduledoc """
  Use case for retrieving a ticket.
  """
  alias WeCraft.Tickets.Infrastructure.Ecto.TicketRepositoryEcto

  def get_ticket(%{ticket_id: ticket_id, scope: _scope}) do
    {:ok, TicketRepositoryEcto.get_ticket(ticket_id)}
  end
end
