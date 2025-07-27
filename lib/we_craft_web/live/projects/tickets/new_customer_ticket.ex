defmodule WeCraftWeb.Projects.Tickets.NewCustomerTicket do
  @moduledoc """
  LiveView for creating a new customer ticket.
  """
  use WeCraftWeb, :live_view

  alias WeCraft.Projects
  alias WeCraft.Tickets
  alias WeCraft.Tickets.Ticket
  alias WeCraftWeb.Projects.Tickets.TicketFormComponent

  def mount(%{"project_id" => project_id}, _session, socket) do
    {:ok, project} =
      Projects.get_project(%{project_id: project_id, scope: socket.assigns.current_scope})

    {:ok,
     socket
     |> assign(:project, project)}
  end

  def handle_info({TicketFormComponent, {:save, params}}, socket) do
    project_id = socket.assigns.project.id
    attrs = Map.put(params, "project_id", project_id)

    case Tickets.create_ticket(attrs) do
      {:ok, _ticket} ->
        {:noreply,
         socket
         |> put_flash(:info, "Ticket created successfully.")
         |> push_navigate(to: "/project/#{project_id}/tickets")}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="project-page min-h-screen bg-gradient-to-br from-base-100 to-base-200">
      <div class="flex h-screen">
        <div class="flex-1 p-8 overflow-y-auto">
          <h1 class="text-2xl font-bold mb-6">Add Ticket</h1>
          <.live_component
            module={TicketFormComponent}
            id="ticket-form"
            ticket={%Ticket{project_id: @project.id}}
            changeset={Ticket.changeset(%Ticket{project_id: @project.id}, %{})}
            submit_event="save"
            cancel_path={~p"/project/#{@project.id}/tickets"}
          />
        </div>
      </div>
    </div>
    """
  end
end
