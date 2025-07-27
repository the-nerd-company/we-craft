defmodule WeCraftWeb.Projects.Milestones.Milestones do
  @moduledoc """
  LiveView for displaying and managing project milestones.
  """
  use WeCraftWeb, :live_view

  alias WeCraft.Chats
  alias WeCraft.{Milestones, Pages, Projects}
  alias WeCraft.Projects.ProjectPermissions
  alias WeCraftWeb.Components.LeftMenu

  def mount(%{"project_id" => project_id}, _session, socket) do
    project_id = String.to_integer(project_id)
    scope = socket.assigns.current_scope

    case Projects.get_project(%{project_id: project_id, scope: scope}) do
      {:ok, nil} ->
        {:ok, push_navigate(socket, to: ~p"/")}

      {:ok, project} ->
        # Get chats for the left menu
        {:ok, chats} = Chats.list_project_chats(%{project_id: project.id})
        {:ok, pages} = Pages.list_project_pages(%{project: project, scope: scope})

        # Load milestones for the project
        milestones = load_project_milestones(project.id, scope)

        # Get active milestones for the left menu
        active_milestones =
          milestones
          |> Enum.filter(&(&1.status == :active))

        {:ok,
         socket
         |> assign(:project, project)
         |> assign(:chats, chats)
         |> assign(:current_chat, nil)
         |> assign(:current_section, :milestones)
         |> assign(:milestones, milestones)
         |> assign(:pages, pages)
         |> assign(:active_milestones, active_milestones)
         |> assign(:editing_task, nil)
         |> assign(:task_form, nil)
         |> assign(:page_title, "Milestones - #{project.title}")}
    end
  end

  def handle_event("edit-milestone", %{"milestone-id" => milestone_id}, socket) do
    milestone_id =
      case milestone_id do
        id when is_binary(id) -> String.to_integer(id)
        id when is_integer(id) -> id
      end

    {:noreply,
     push_navigate(socket,
       to: ~p"/project/#{socket.assigns.project.id}/milestones/#{milestone_id}/edit"
     )}
  end

  def handle_event("complete-milestone", %{"milestone-id" => milestone_id}, socket) do
    milestone_id =
      case milestone_id do
        id when is_binary(id) -> String.to_integer(id)
        id when is_integer(id) -> id
      end

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

      {:error, _} ->
        send(self(), {:show_flash, :error, "Failed to update milestone"})
        {:noreply, socket}
    end
  end

  def handle_event("delete-milestone", %{"milestone-id" => milestone_id}, socket) do
    milestone_id =
      case milestone_id do
        id when is_binary(id) -> String.to_integer(id)
        id when is_integer(id) -> id
      end

    case Milestones.delete_milestone(%{
           milestone_id: milestone_id,
           scope: socket.assigns.current_scope
         }) do
      {:ok, _milestone} ->
        milestones =
          load_project_milestones(socket.assigns.project.id, socket.assigns.current_scope)

        send(self(), {:show_flash, :info, "Milestone deleted successfully"})
        {:noreply, assign(socket, :milestones, milestones)}

      {:error, _} ->
        send(self(), {:show_flash, :error, "Failed to delete milestone"})
        {:noreply, socket}
    end
  end

  # Task event handlers
  def handle_event("add-task", %{"milestone-id" => milestone_id}, socket) do
    milestone_id =
      case milestone_id do
        id when is_binary(id) -> String.to_integer(id)
        id when is_integer(id) -> id
      end

    # Create a simple task and immediately put it in edit mode
    case Milestones.create_task(%{
           attrs: %{
             title: "New Task",
             description: "Task description",
             status: "planned",
             milestone_id: milestone_id
           },
           scope: socket.assigns.current_scope
         }) do
      {:ok, task} ->
        milestones =
          load_project_milestones(socket.assigns.project.id, socket.assigns.current_scope)

        # Immediately edit the new task
        changeset = WeCraft.Milestones.Task.changeset(task, %{})

        send(self(), {:show_flash, :info, "Task added successfully! Click edit to customize."})

        {:noreply,
         socket
         |> assign(:milestones, milestones)
         |> assign(:editing_task, task.id)
         |> assign(:task_form, to_form(changeset))}

      {:error, _reason} ->
        send(self(), {:show_flash, :error, "Failed to add task"})
        {:noreply, socket}
    end
  end

  def handle_event("complete-task", %{"task-id" => task_id}, socket) do
    task_id =
      case task_id do
        id when is_binary(id) -> String.to_integer(id)
        id when is_integer(id) -> id
      end

    case Milestones.update_task(%{
           task_id: task_id,
           attrs: %{status: :completed},
           scope: socket.assigns.current_scope
         }) do
      {:ok, _task} ->
        milestones =
          load_project_milestones(socket.assigns.project.id, socket.assigns.current_scope)

        send(self(), {:show_flash, :info, "Task completed!"})
        {:noreply, assign(socket, :milestones, milestones)}

      {:error, _} ->
        send(self(), {:show_flash, :error, "Failed to complete task"})
        {:noreply, socket}
    end
  end

  def handle_event("delete-task", %{"task-id" => task_id}, socket) do
    task_id =
      case task_id do
        id when is_binary(id) -> String.to_integer(id)
        id when is_integer(id) -> id
      end

    case Milestones.delete_task(%{
           task_id: task_id,
           scope: socket.assigns.current_scope
         }) do
      {:ok, _task} ->
        milestones =
          load_project_milestones(socket.assigns.project.id, socket.assigns.current_scope)

        send(self(), {:show_flash, :info, "Task deleted successfully"})
        {:noreply, assign(socket, :milestones, milestones)}

      {:error, _} ->
        send(self(), {:show_flash, :error, "Failed to delete task"})
        {:noreply, socket}
    end
  end

  def handle_event("edit-task", %{"task-id" => task_id}, socket) do
    task_id =
      case task_id do
        id when is_binary(id) -> String.to_integer(id)
        id when is_integer(id) -> id
      end

    # Find the task to edit
    case Milestones.get_task(%{task_id: task_id, scope: socket.assigns.current_scope}) do
      {:ok, task} when not is_nil(task) ->
        changeset = WeCraft.Milestones.Task.changeset(task, %{})

        {:noreply,
         socket
         |> assign(:editing_task, task_id)
         |> assign(:task_form, to_form(changeset))}

      _ ->
        send(self(), {:show_flash, :error, "Task not found"})
        {:noreply, socket}
    end
  end

  def handle_event("cancel-edit-task", _params, socket) do
    {:noreply,
     socket
     |> assign(:editing_task, nil)
     |> assign(:task_form, nil)}
  end

  def handle_event("validate-task", %{"task" => task_params}, socket) do
    if socket.assigns.editing_task do
      case Milestones.get_task(%{
             task_id: socket.assigns.editing_task,
             scope: socket.assigns.current_scope
           }) do
        {:ok, task} when not is_nil(task) ->
          changeset =
            task
            |> WeCraft.Milestones.Task.changeset(task_params)
            |> Map.put(:action, :validate)

          {:noreply, assign(socket, :task_form, to_form(changeset))}

        _ ->
          {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end

  def handle_event("save-task", %{"task" => task_params}, socket) do
    if socket.assigns.editing_task do
      case Milestones.update_task(%{
             task_id: socket.assigns.editing_task,
             attrs: task_params,
             scope: socket.assigns.current_scope
           }) do
        {:ok, _task} ->
          milestones =
            load_project_milestones(socket.assigns.project.id, socket.assigns.current_scope)

          send(self(), {:show_flash, :info, "Task updated successfully!"})

          {:noreply,
           socket
           |> assign(:milestones, milestones)
           |> assign(:editing_task, nil)
           |> assign(:task_form, nil)}

        {:error, %Ecto.Changeset{} = changeset} ->
          {:noreply, assign(socket, :task_form, to_form(changeset))}

        {:error, _} ->
          send(self(), {:show_flash, :error, "Failed to update task"})
          {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end

  # Handle left menu events
  def handle_info({:chat_selected, chat_id}, socket) do
    case Enum.find(socket.assigns.chats, &(&1.id == chat_id)) do
      nil ->
        {:noreply, socket}

      _chat ->
        {:noreply, push_navigate(socket, to: ~p"/project/#{socket.assigns.project.id}")}
    end
  end

  def handle_info({:section_changed, :chat}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/project/#{socket.assigns.project.id}")}
  end

  def handle_info({:section_changed, :milestones}, socket) do
    # Already on milestones page
    {:noreply, socket}
  end

  def handle_info({:show_flash, kind, message}, socket) do
    {:noreply, put_flash(socket, kind, message)}
  end

  def handle_info(:open_new_channel_modal, socket) do
    {:noreply, push_navigate(socket, to: ~p"/project/#{socket.assigns.project.id}")}
  end

  defp load_project_milestones(project_id, scope) do
    case Milestones.list_project_milestones(%{project_id: project_id, scope: scope}) do
      {:ok, milestones} -> milestones
      {:error, _} -> []
    end
  end

  defp milestone_status_color(:planned), do: "bg-info"
  defp milestone_status_color(:active), do: "bg-warning"
  defp milestone_status_color(:completed), do: "bg-success"

  defp milestone_status_badge_class(:planned), do: "badge-info"
  defp milestone_status_badge_class(:active), do: "badge-warning"
  defp milestone_status_badge_class(:completed), do: "badge-success"

  defp format_status(:planned), do: "Planned"
  defp format_status(:active), do: "Active"
  defp format_status(:completed), do: "Completed"

  defp format_date(nil), do: "No date set"

  defp format_date(datetime) do
    datetime
    |> NaiveDateTime.to_date()
    |> Calendar.strftime("%B %d, %Y")
  end

  defp task_status_color(:planned), do: "bg-info"
  defp task_status_color(:active), do: "bg-warning"
  defp task_status_color(:completed), do: "bg-success"

  defp task_status_badge_class(:planned), do: "badge-info"
  defp task_status_badge_class(:active), do: "badge-warning"
  defp task_status_badge_class(:completed), do: "badge-success"

  defp format_task_status(:planned), do: "Planned"
  defp format_task_status(:active), do: "Active"
  defp format_task_status(:completed), do: "Completed"

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
        
    <!-- Main Content Area -->
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
                          
    <!-- Tasks Section -->
                          <div class="mt-4">
                            <div class="flex items-center justify-between mb-2">
                              <h4 class="text-sm font-medium text-base-content/80">
                                Tasks ({length(milestone.tasks)})
                              </h4>
                              <%= if ProjectPermissions.can_update_project?(@project, @current_scope) do %>
                                <button
                                  phx-click="add-task"
                                  phx-value-milestone-id={milestone.id}
                                  class="btn btn-ghost btn-xs"
                                >
                                  <.icon name="hero-plus" class="w-3 h-3" /> Add Task
                                </button>
                              <% end %>
                            </div>

                            <%= if Enum.empty?(milestone.tasks) do %>
                              <p class="text-xs text-base-content/50 italic">No tasks yet</p>
                            <% else %>
                              <div class="space-y-2">
                                <%= for task <- milestone.tasks do %>
                                  <%= if @editing_task == task.id do %>
                                    <!-- Editing Form -->
                                    <div class="p-3 bg-base-50 rounded-lg border border-primary/20">
                                      <.form
                                        for={@task_form}
                                        phx-change="validate-task"
                                        phx-submit="save-task"
                                        class="space-y-3"
                                      >
                                        <!-- Task Title -->
                                        <div class="form-control">
                                          <.input
                                            field={@task_form[:title]}
                                            type="text"
                                            placeholder="Task title..."
                                            class="input input-bordered input-sm w-full"
                                            required
                                          />
                                        </div>
                                        
    <!-- Task Description -->
                                        <div class="form-control">
                                          <.input
                                            field={@task_form[:description]}
                                            type="textarea"
                                            placeholder="Task description..."
                                            class="textarea textarea-bordered textarea-sm w-full h-20"
                                            required
                                          />
                                        </div>
                                        
    <!-- Task Status -->
                                        <div class="form-control">
                                          <.input
                                            field={@task_form[:status]}
                                            type="select"
                                            options={[
                                              {"Planned", "planned"},
                                              {"Active", "active"},
                                              {"Completed", "completed"}
                                            ]}
                                            class="select select-bordered select-sm w-full"
                                            required
                                          />
                                        </div>
                                        
    <!-- Action Buttons -->
                                        <div class="flex justify-end gap-2">
                                          <button
                                            type="button"
                                            phx-click="cancel-edit-task"
                                            class="btn btn-ghost btn-sm"
                                          >
                                            Cancel
                                          </button>
                                          <button
                                            type="submit"
                                            class="btn btn-primary btn-sm"
                                            disabled={!@task_form.source.valid?}
                                          >
                                            <.icon name="hero-check" class="w-3 h-3 mr-1" /> Save
                                          </button>
                                        </div>
                                      </.form>
                                    </div>
                                  <% else %>
                                    <!-- Task Display -->
                                    <div class="p-2 bg-base-50 rounded-lg">
                                      <div class="flex items-start justify-between">
                                        <div class="flex-1">
                                          <div class="flex items-center gap-2 mb-1">
                                            <div class={
                                              "w-2 h-2 rounded-full #{task_status_color(task.status)}"
                                            }>
                                            </div>
                                            <span class="text-sm font-medium text-base-content">
                                              {task.title}
                                            </span>
                                            <span class={
                                              "badge badge-xs #{task_status_badge_class(task.status)}"
                                            }>
                                              {format_task_status(task.status)}
                                            </span>
                                          </div>
                                          <%= if task.description && task.description != "" do %>
                                            <p class="text-xs text-base-content/70 ml-4">
                                              {task.description}
                                            </p>
                                          <% end %>
                                        </div>
                                        <%= if ProjectPermissions.can_update_project?(@project, @current_scope) do %>
                                          <div class="flex items-center gap-1">
                                            <button
                                              phx-click="edit-task"
                                              phx-value-task-id={task.id}
                                              class="btn btn-ghost btn-xs"
                                              title="Edit task"
                                            >
                                              <.icon name="hero-pencil-square" class="w-3 h-3" />
                                            </button>
                                            <%= if task.status != :completed do %>
                                              <button
                                                phx-click="complete-task"
                                                phx-value-task-id={task.id}
                                                class="btn btn-ghost btn-xs text-success"
                                                title="Mark as completed"
                                              >
                                                <.icon name="hero-check" class="w-3 h-3" />
                                              </button>
                                            <% end %>
                                            <button
                                              phx-click="delete-task"
                                              phx-value-task-id={task.id}
                                              class="btn btn-ghost btn-xs text-error"
                                              title="Delete task"
                                            >
                                              <.icon name="hero-trash" class="w-3 h-3" />
                                            </button>
                                          </div>
                                        <% end %>
                                      </div>
                                    </div>
                                  <% end %>
                                <% end %>
                              </div>
                            <% end %>
                          </div>
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
                                >
                                  <.icon name="hero-pencil-square" class="w-4 h-4" /> Edit
                                </button>
                              </li>
                              <%= if milestone.status != :completed do %>
                                <li>
                                  <button
                                    phx-click="complete-milestone"
                                    phx-value-milestone-id={milestone.id}
                                  >
                                    <.icon name="hero-check" class="w-4 h-4" /> Mark Complete
                                  </button>
                                </li>
                              <% end %>
                              <li>
                                <button
                                  phx-click="delete-milestone"
                                  phx-value-milestone-id={milestone.id}
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
      </div>
    </div>
    """
  end
end
