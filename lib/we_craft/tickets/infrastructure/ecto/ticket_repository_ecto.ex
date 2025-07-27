defmodule WeCraft.Tickets.Infrastructure.Ecto.TicketRepositoryEcto do
  @moduledoc """
  Ecto-based implementation of the ticket repository.
  """
  alias WeCraft.Repo
  alias WeCraft.Tickets.Ticket

  import Ecto.Query, warn: false

  def list_tickets_by_project(project_id) do
    Repo.all(
      from t in Ticket,
        where: t.project_id == ^project_id,
        order_by: [desc: t.inserted_at]
    )
  end

  def get_ticket(id), do: Repo.get(Ticket, id)

  def create_ticket(attrs) do
    %Ticket{}
    |> Ticket.changeset(attrs)
    |> Repo.insert()
  end

  def update_ticket(%Ticket{} = ticket, attrs) do
    ticket
    |> Ticket.changeset(attrs)
    |> Repo.update()
  end

  def delete_ticket(%Ticket{} = ticket) do
    Repo.delete(ticket)
  end
end
