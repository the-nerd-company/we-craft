defmodule WeCraft.Tickets.UseCases.CreateTicketUseCaseTest do
  @moduledoc """
  Test suite for the CreateTicketUseCase.
  """
  use WeCraft.DataCase, async: true

  import WeCraft.ProjectsFixtures

  alias WeCraft.Tickets

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

    {:ok, ticket} = Tickets.create_ticket(attrs)
    assert ticket.id
    assert ticket.title == "Create UseCase Test"
  end
end
