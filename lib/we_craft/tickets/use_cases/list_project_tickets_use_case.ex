defmodule WeCraft.Tickets.UseCases.ListProjectTicketsUseCase do
  @moduledoc """
  Use case for listing tickets by project.
  """
  alias WeCraft.Tickets.Infrastructure.Ecto.TicketRepositoryEcto

  def list_tickets(%{project: project}) do
    {:ok, TicketRepositoryEcto.list_tickets_by_project(project.id)}
  end
end
