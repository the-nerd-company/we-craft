defmodule WeCraftWeb.Projects.Tickets.ShowCustomerTicket do
  @moduledoc """
  LiveView for displaying a customer ticket.
  """
  use WeCraftWeb, :live_view

  alias WeCraft.{Projects, Tickets}
  alias WeCraftWeb.Components.LeftMenu
  alias WeCraftWeb.Projects.Tickets.Components.TicketStatusColor
  alias WeCraftWeb.Projects.Tickets.Components.TicketStatusFormat

  def mount(%{"project_id" => project_id, "ticket_id" => ticket_id}, _session, socket) do
    {:ok, project} =
      Projects.get_project(%{project_id: project_id, scope: socket.assigns.current_scope})

    {:ok, ticket} =
      Tickets.get_ticket(%{scope: socket.assigns.current_scope, ticket_id: ticket_id})

    socket
    |> assign(:ticket, ticket)
    |> assign(:project, project)
    |> LeftMenu.load_menu_data(%{"project_id" => project_id})
  end

  def render(assigns) do
    ~H"""
    <div class="project-page min-h-screen bg-gradient-to-br from-base-100 to-base-200">
      <div class="flex h-screen">
        <!-- Left Menu -->
        <.live_component
          module={LeftMenu}
          id="left-menu"
          project={@project}
          pages={@pages}
          current_scope={@current_scope}
          current_section={@current_section}
          chats={@chats}
          current_chat={@current_chat}
          active_milestones={@active_milestones}
        />
        <div class="flex-1 p-8 overflow-y-auto flex flex-col items-center">
          <div class="card w-full max-w-2xl bg-base-100 shadow-xl border border-base-200">
            <div class="card-body">
              <div class="flex items-center gap-4 mb-2">
                <h2 class="card-title text-3xl font-bold">{@ticket.title}</h2>
                <span class="badge badge-info badge-lg capitalize">
                  {TicketStatusFormat.format_ticket_type(@ticket.type)}
                </span>
                <span class={"badge badge-" <> TicketStatusColor.status_color(@ticket.status) <> " badge-lg capitalize"}>
                  {TicketStatusFormat.format_ticket_status(@ticket.status)}
                </span>
              </div>
              <div class="flex items-center gap-4 mb-4">
                <span class="badge badge-outline">Priority: {@ticket.priority}</span>
                <span :if={@ticket.customer_id} class="badge badge-ghost">
                  Customer ID: {@ticket.customer_id}
                </span>
              </div>
              <div class="prose max-w-none mb-4">
                <h3 class="mb-1 text-lg font-semibold">Description</h3>
                <p>{@ticket.description}</p>
              </div>
              <div class="card-actions justify-end mt-6">
                <.link patch={~p"/project/#{@project.id}/tickets"} class="btn btn-outline">
                  Back to tickets
                </.link>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
