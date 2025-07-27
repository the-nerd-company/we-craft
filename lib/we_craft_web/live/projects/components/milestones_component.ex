defmodule WeCraftWeb.Projects.Components.MilestonesComponent do
  @moduledoc """
  A component for displaying and managing project milestones.
  """
  use WeCraftWeb, :live_component

  alias WeCraft.{Milestones, Projects.ProjectPermissions}

  # Required assigns
  attr :id, :string, required: true
  attr :project, :map, required: true
  attr :current_scope, :map, required: true

  def mount(socket) do
    {:ok, assign(socket, :milestones, [])}
  end

  def update(assigns, socket) do
    # Load milestones for the project
    milestones = load_project_milestones(assigns.project.id, assigns.current_scope)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:milestones, milestones)}
  end

  def render(assigns) do
    ~H"""
    <div class="flex-1 flex flex-col bg-base-100">
      <!-- Header -->
      <div class="p-6 border-b border-base-200">
        <div class="flex items-center justify-between">
          <div>
            <h1 class="text-2xl font-bold text-base-content">Milestones</h1>
            <p class="text-base-content/70 mt-1">Track project progress and goals</p>
          </div>
          <%= if ProjectPermissions.can_update_project?(@project, @current_scope) do %>
            <.link navigate={~p"/project/#{@project.id}/milestones/new"} class="btn btn-primary">
              <.icon name="hero-plus" class="w-4 h-4 mr-2" /> New Milestone
            </.link>
          <% end %>
        </div>
      </div>
      
    <!-- Content -->
      <div class="flex-1 overflow-y-auto p-6">
        <%= if Enum.empty?(@milestones) do %>
          <div class="flex flex-col items-center justify-center h-64 text-center">
            <div class="w-16 h-16 bg-base-200 rounded-full flex items-center justify-center mb-4">
              <.icon name="hero-flag" class="w-8 h-8 text-base-content/40" />
            </div>
            <h3 class="text-lg font-medium text-base-content mb-2">No milestones yet</h3>
            <p class="text-base-content/70 mb-4 max-w-md">
              Set milestones to track important goals and deadlines for your project.
            </p>
            <%= if ProjectPermissions.can_update_project?(@project, @current_scope) do %>
              <.link navigate={~p"/project/#{@project.id}/milestones/new"} class="btn btn-primary">
                Create Your First Milestone
              </.link>
            <% end %>
          </div>
        <% else %>
          <div class="space-y-4">
            <%= for milestone <- @milestones do %>
              <div class="card bg-base-100 border border-base-200 shadow-sm">
                <div class="card-body p-6">
                  <div class="flex items-start justify-between">
                    <div class="flex-1">
                      <div class="flex items-center gap-3 mb-2">
                        <div class={
                          "w-3 h-3 rounded-full #{milestone_status_color(milestone.status)}"
                        }>
                        </div>
                        <h3 class="text-lg font-semibold text-base-content">
                          {milestone.title}
                        </h3>
                        <span class={
                          "badge #{milestone_status_badge_class(milestone.status)}"
                        }>
                          {format_status(milestone.status)}
                        </span>
                      </div>
                      <%= if milestone.description do %>
                        <p class="text-base-content/70 mb-3">{milestone.description}</p>
                      <% end %>
                      <%= if milestone.due_date do %>
                        <div class="flex items-center gap-2 text-sm text-base-content/60">
                          <.icon name="hero-calendar" class="w-4 h-4" />
                          <span>Due: {format_date(milestone.due_date)}</span>
                          <%= if Date.compare(NaiveDateTime.to_date(milestone.due_date), Date.utc_today()) == :lt and milestone.status != :completed do %>
                            <span class="text-error font-medium">(Overdue)</span>
                          <% end %>
                        </div>
                      <% end %>
                    </div>
                    <%= if ProjectPermissions.can_update_project?(@project, @current_scope) do %>
                      <div class="dropdown dropdown-end">
                        <div tabindex="0" role="button" class="btn btn-ghost btn-sm btn-circle">
                          <.icon name="hero-ellipsis-vertical" class="w-4 h-4" />
                        </div>
                        <ul
                          tabindex="0"
                          class="menu menu-sm dropdown-content bg-base-100 rounded-box z-[1] mt-3 w-48 p-2 shadow"
                        >
                          <li>
                            <button
                              phx-click="edit-milestone"
                              phx-value-milestone-id={milestone.id}
                              phx-target={@myself}
                            >
                              <.icon name="hero-pencil-square" class="w-4 h-4" /> Edit
                            </button>
                          </li>
                          <%= if milestone.status != :completed do %>
                            <li>
                              <button
                                phx-click="complete-milestone"
                                phx-value-milestone-id={milestone.id}
                                phx-target={@myself}
                              >
                                <.icon name="hero-check" class="w-4 h-4" /> Mark Complete
                              </button>
                            </li>
                          <% end %>
                          <li>
                            <button
                              phx-click="delete-milestone"
                              phx-value-milestone-id={milestone.id}
                              phx-target={@myself}
                              class="text-error"
                            >
                              <.icon name="hero-trash" class="w-4 h-4" /> Delete
                            </button>
                          </li>
                        </ul>
                      </div>
                    <% end %>
                  </div>
                </div>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  def handle_event("edit-milestone", %{"milestone-id" => _milestone_id}, socket) do
    send(self(), {:show_flash, :info, "Milestone editing will be implemented soon"})
    {:noreply, socket}
  end

  def handle_event("complete-milestone", %{"milestone-id" => milestone_id}, socket) do
    milestone_id = String.to_integer(milestone_id)

    case Milestones.update_milestone(%{
           milestone_id: milestone_id,
           attrs: %{status: :completed, completed_at: NaiveDateTime.utc_now()},
           scope: socket.assigns.current_scope
         }) do
      {:ok, _milestone} ->
        milestones =
          load_project_milestones(socket.assigns.project.id, socket.assigns.current_scope)

        send(self(), {:show_flash, :info, "Milestone marked as completed!"})
        {:noreply, assign(socket, :milestones, milestones)}

      {:error, _changeset} ->
        send(self(), {:show_flash, :error, "Failed to update milestone"})
        {:noreply, socket}
    end
  end

  def handle_event("delete-milestone", %{"milestone-id" => milestone_id}, socket) do
    milestone_id = String.to_integer(milestone_id)

    case Milestones.delete_milestone(%{
           milestone_id: milestone_id,
           scope: socket.assigns.current_scope
         }) do
      {:ok, _milestone} ->
        milestones =
          load_project_milestones(socket.assigns.project.id, socket.assigns.current_scope)

        send(self(), {:show_flash, :info, "Milestone deleted successfully"})
        {:noreply, assign(socket, :milestones, milestones)}

      {:error, _reason} ->
        send(self(), {:show_flash, :error, "Failed to delete milestone"})
        {:noreply, socket}
    end
  end

  defp load_project_milestones(project_id, scope) do
    case Milestones.list_project_milestones(%{project_id: project_id, scope: scope}) do
      {:ok, milestones} -> milestones
      {:error, _} -> []
    end
  end

  defp milestone_status_color(status) do
    case status do
      :planned -> "bg-base-300"
      :active -> "bg-primary"
      :completed -> "bg-success"
      _ -> "bg-base-300"
    end
  end

  defp milestone_status_badge_class(status) do
    case status do
      :planned -> "badge-ghost"
      :active -> "badge-primary"
      :completed -> "badge-success"
      _ -> "badge-ghost"
    end
  end

  defp format_status(status) do
    case status do
      :planned -> "Planned"
      :active -> "Active"
      :completed -> "Completed"
      _ -> "Unknown"
    end
  end

  defp format_date(naive_datetime) do
    naive_datetime
    |> NaiveDateTime.to_date()
    |> Calendar.strftime("%B %d, %Y")
  end
end
