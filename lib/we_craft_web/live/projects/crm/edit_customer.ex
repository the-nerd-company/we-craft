defmodule WeCraftWeb.Projects.CRM.EditCustomer do
  @moduledoc """
  LiveView for editing a customer in a CRM project.
  """
  use WeCraftWeb, :live_view

  alias WeCraft.{CRM, Projects}
  alias WeCraft.CRM.Customer
  alias WeCraft.CRM.Infrastructure.Ecto.CustomerRepositoryEcto
  alias WeCraftWeb.Components.LeftMenu
  alias WeCraftWeb.Projects.CRM.CustomerFormComponent

  def mount(%{"project_id" => project_id, "customer_id" => customer_id}, _session, socket) do
    {:ok, project} =
      Projects.get_project(%{project_id: project_id, scope: socket.assigns.current_scope})

    customer = CustomerRepositoryEcto.get_customer(customer_id)
    changeset = Customer.changeset(customer, %{})

    socket
    |> assign(:project, project)
    |> assign(:customer, customer)
    |> assign(:changeset, changeset)
    |> LeftMenu.load_menu_data(%{"project_id" => project_id})
  end

  def handle_info({CustomerFormComponent, {:save, params}}, socket) do
    scope = socket.assigns.current_scope
    project = socket.assigns.project
    customer = socket.assigns.customer

    case CRM.update_customer(%{project: project, customer: customer, attrs: params, scope: scope}) do
      {:ok, _customer} ->
        {:noreply,
         socket
         |> put_flash(:info, "Customer updated successfully.")
         |> push_navigate(to: "/project/#{project.id}/customers")}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
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
          <h1 class="text-2xl font-bold mb-6">Edit Customer</h1>
          <.live_component
            module={CustomerFormComponent}
            id="customer-form"
            customer={@customer}
            changeset={@changeset}
            submit_event="save"
            cancel_path={~p"/project/#{@project.id}/customers"}
          />
        </div>
      </div>
    </div>
    """
  end
end
