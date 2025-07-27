defmodule WeCraft.Tickets.UseCases.CreateTicketUseCaseTest do
  @moduledoc """
  Test suite for the CreateTicketUseCase.
  """
  use WeCraft.DataCase, async: true

  import WeCraft.ProjectsFixtures

  alias WeCraft.Tickets.Infrastructure.Ecto.TicketRepositoryEcto
  alias WeCraft.Tickets.UseCases.CreateTicketUseCase

  test "creates a ticket" do
    project = project_fixture()

    attrs = %{
      title: "Create UseCase Test",
      description: "desc",
      type: :feature_request,
      status: :new,
      priority: 1,
      project_id: project.id
    }

    {:ok, ticket} = CreateTicketUseCase.create_ticket(attrs)
    assert ticket.id
    assert ticket.title == "Create UseCase Test"
    TicketRepositoryEcto.delete_ticket(ticket)
  end
end
