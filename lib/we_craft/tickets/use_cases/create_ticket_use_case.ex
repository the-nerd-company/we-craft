defmodule WeCraft.Tickets.UseCases.CreateTicketUseCase do
  @moduledoc """
  Use case for creating a ticket.
  """
  alias WeCraft.Tickets.Infrastructure.Ecto.TicketRepositoryEcto

  def create_ticket(attrs) do
    TicketRepositoryEcto.create_ticket(attrs)
  end
end
