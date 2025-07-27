defmodule WeCraft.Tickets do
  @moduledoc """
  Context for managing tickets within the application.
  """

  alias WeCraft.Tickets.UseCases.{
    CreateTicketUseCase,
    DeleteTicketUseCase,
    GetTicketUseCase,
    ListProjectTicketsUseCase,
    UpdateTicketUseCase
  }

  defdelegate get_ticket(params), to: GetTicketUseCase
  defdelegate create_ticket(params), to: CreateTicketUseCase
  defdelegate update_ticket(params), to: UpdateTicketUseCase
  defdelegate delete_ticket(params), to: DeleteTicketUseCase
  defdelegate list_tickets(params), to: ListProjectTicketsUseCase
end
