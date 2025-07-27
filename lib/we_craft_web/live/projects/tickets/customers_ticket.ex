alias WeCraftWeb.Projects.Tickets.Components.TicketStatusColor

defmodule WeCraftWeb.Projects.Tickets.CustomersTicket do
  @moduledoc """
  LiveView for displaying and managing customer tickets.
  """
  use WeCraftWeb, :live_view

  alias WeCraft.{Projects, Tickets}
  alias WeCraftWeb.Components.LeftMenu
  alias WeCraftWeb.Projects.Tickets.Components.TicketStatusFormat

  def mount(%{"project_id" => project_id}, _session, socket) do
    {:ok, project} =
      Projects.get_project(%{project_id: project_id, scope: socket.assigns.current_scope})

    {:ok, tickets} =
      Tickets.list_tickets(%{project: project, scope: socket.assigns.current_scope})

    socket
    |> assign(:tickets, tickets)
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
        <div class="flex-1 p-8 overflow-y-auto">
          <h1 class="text-2xl font-bold mb-6">Customer Tickets</h1>
          <div class="overflow-x-auto">
            <table class="table table-zebra rounded-xl bg-base-100 shadow-xl border border-base-200 text-sm">
              <thead>
                <tr class="bg-base-200">
                  <th class="text-left font-normal">Title</th>
                  <th class="text-left font-normal">Type</th>
                  <th class="text-left font-normal">Status</th>
                  <th class="text-left font-normal">Priority</th>
                  <th class="text-left font-normal">Description</th>
                  <th class="text-left font-normal">Actions</th>
                </tr>
              </thead>
              <tbody>
                <%= for ticket <- @tickets do %>
                  <tr class="hover:bg-base-200 transition-colors">
                    <td class="text-base-content font-normal">
                      {ticket.title}
                    </td>
                    <td>
                      <span class="badge badge-info badge-md capitalize">
                        {TicketStatusFormat.format_ticket_type(ticket.type)}
                      </span>
                    </td>
                    <td>
                      <span class={"badge badge-" <> TicketStatusColor.status_color(ticket.status) <> " badge-md capitalize"}>
                        {TicketStatusFormat.format_ticket_status(ticket.status)}
                      </span>
                    </td>
                    <td>
                      <span class="badge badge-outline">P: {ticket.priority}</span>
                    </td>
                    <td class="text-base-content/80 max-w-xs truncate font-normal">
                      {ticket.description}
                    </td>
                    <td>
                      <.button
                        navigate={~p"/project/#{@project.id}/tickets/#{ticket.id}"}
                        class="btn btn-sm btn-ghost border border-2 border-base-300 flex items-center gap-2"
                      >
                        <.icon name="hero-eye" class="w-4 h-4" />
                        <span>Details</span>
                      </.button>
                    </td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
