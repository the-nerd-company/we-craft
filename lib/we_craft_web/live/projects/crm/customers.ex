defmodule WeCraftWeb.Projects.CRM.Customers do
  @moduledoc """
  LiveView for listing customers in a CRM project.
  """
  use WeCraftWeb, :live_view

  alias WeCraft.{CRM, Projects}
  alias WeCraftWeb.Components.LeftMenu

  def mount(%{"project_id" => project_id}, _session, socket) do
    {:ok, project} =
      Projects.get_project(%{project_id: project_id, scope: socket.assigns.current_scope})

    {:ok, customers} =
      CRM.list_customers(%{project: project, scope: socket.assigns.current_scope})

    socket
    |> assign(:customers, customers)
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
          <div class="flex justify-between items-center mb-6">
            <h1 class="text-2xl font-bold">Customers</h1>
            <.link patch={~p"/project/#{@project.id}/customers/new"} class="btn btn-primary">
              Add Customer
            </.link>
          </div>
          <div class="overflow-x-auto">
            <table class="table table-zebra rounded-xl bg-base-100 shadow-xl border border-base-200 text-sm">
              <thead>
                <tr class="bg-base-200">
                  <th class="text-left font-normal">Name</th>
                  <th class="text-left font-normal">Email</th>
                  <th class="text-left font-normal">External ID</th>
                  <th class="text-left font-normal">Tags</th>
                  <th class="text-left font-normal">Actions</th>
                </tr>
              </thead>
              <tbody>
                <%= for customer <- @customers do %>
                  <tr class="hover:bg-base-200 transition-colors">
                    <td class="text-base-content font-normal">
                      {customer.name}
                    </td>
                    <td class="font-normal">
                      {customer.email}
                    </td>
                    <td class="font-normal">
                      {customer.external_id}
                    </td>
                    <td class="font-normal">
                      <span class="badge badge-ghost">{Enum.join(customer.tags || [], ", ")}</span>
                    </td>
                    <td>
                      <.link
                        patch={~p"/project/#{@project.id}/customers/#{customer.id}/edit"}
                        class="btn btn-sm btn-ghost border border-2 border-base-300 flex items-center gap-2"
                        title="Edit"
                      >
                        <.icon name="hero-eye" class="w-4 h-4" />
                        <span>Details</span>
                      </.link>
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
