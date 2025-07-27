defmodule WeCraftWeb.Projects.Milestones.EditMilestone do
  @moduledoc """
  LiveView for editing individual milestones
  """

  use WeCraftWeb, :live_view

  alias WeCraft.Milestones.Task
  alias WeCraft.{Chats, Milestones, Pages, Projects}
  alias WeCraft.Milestones.Milestone
  alias WeCraftWeb.Components.LeftMenu

  def mount(%{"project_id" => project_id, "milestone_id" => milestone_id}, _session, socket) do
    project_id = String.to_integer(project_id)
    milestone_id = String.to_integer(milestone_id)
    scope = socket.assigns.current_scope

    case Projects.get_project(%{project_id: project_id, scope: scope}) do
      {:ok, nil} ->
        {:ok, push_navigate(socket, to: ~p"/")}

      {:ok, project} ->
        with {:ok, milestone} when not is_nil(milestone) <- get_milestone(milestone_id, scope),
             true <- milestone.project_id == project.id do
          # Get chats for the left menu
          {:ok, chats} = Chats.list_project_chats(%{project_id: project.id})
          {:ok, pages} = Pages.list_project_pages(%{project: project, scope: scope})

          # Get active milestones for the left menu
          active_milestones = get_active_milestones(project.id, scope)

          changeset = Milestone.changeset(milestone, %{})

          {:ok,
           socket
           |> assign(:project, project)
           |> assign(:milestone, milestone)
           |> assign(:chats, chats)
           |> assign(:current_chat, nil)
           |> assign(:current_section, :milestones)
           |> assign(:active_milestones, active_milestones)
           |> assign(:changeset, changeset)
           |> assign(:form, to_form(changeset))
           |> assign(:editing_task, nil)
           |> assign(:task_form, nil)
           |> assign(:pages, pages)
           |> assign(:page_title, "Edit Milestone - #{project.title}")
           |> assign(:form_errors, [])}
        else
          {:ok, nil} ->
            {:ok,
             socket
             |> put_flash(:error, "Milestone not found")
             |> push_navigate(to: ~p"/project/#{project.id}/milestones")}

          false ->
            {:ok,
             socket
             |> put_flash(:error, "Milestone not found")
             |> push_navigate(to: ~p"/project/#{project.id}/milestones")}

          {:error, :unauthorized} ->
            {:ok,
             socket
             |> put_flash(:error, "You don't have permission to edit this milestone")
             |> push_navigate(to: ~p"/project/#{project.id}/milestones")}
        end
    end
  end

  # Task event handlers
  def handle_event("add-task", _params, socket) do
    case Milestones.create_task(%{
           attrs: %{
             title: "New Task",
             description: "Task description",
             status: "planned",
             milestone_id: socket.assigns.milestone.id
           },
           scope: socket.assigns.current_scope
         }) do
      {:ok, task} ->
        # Set the new task to editing mode immediately
        changeset = Task.changeset(task, %{})

        # Reload the milestone with updated tasks
        case get_milestone(socket.assigns.milestone.id, socket.assigns.current_scope) do
          {:ok, updated_milestone} when not is_nil(updated_milestone) ->
            send(self(), {:show_flash, :info, "Task added successfully!"})

            {:noreply,
             socket
             |> assign(:milestone, updated_milestone)
             |> assign(:editing_task, task.id)
             |> assign(:task_form, to_form(changeset))}

          _ ->
            send(self(), {:show_flash, :error, "Failed to reload milestone"})
            {:noreply, socket}
        end

      {:error, _} ->
        send(self(), {:show_flash, :error, "Failed to add task"})
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
    task = Enum.find(socket.assigns.milestone.tasks, &(&1.id == task_id))

    if task do
      changeset = Task.changeset(task, %{})

      {:noreply,
       socket
       |> assign(:editing_task, task_id)
       |> assign(:task_form, to_form(changeset))}
    else
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
    # Find the task being edited
    task =
      if task_id = socket.assigns.editing_task do
        Enum.find(socket.assigns.milestone.tasks, &(&1.id == task_id))
      end

    if task do
      changeset =
        task
        |> WeCraft.Milestones.Task.changeset(task_params)
        |> Map.put(:action, :validate)

      {:noreply, assign(socket, :task_form, to_form(changeset))}
    else
      # If no task found, don't update the form - keep current state
      {:noreply, socket}
    end
  end

  def handle_event("save-task", %{"task" => task_params}, socket) do
    task_id = socket.assigns.editing_task

    if is_nil(task_id) do
      {:noreply, socket}
    else
      with {:ok, _task} <-
             Milestones.update_task(%{
               task_id: task_id,
               attrs: task_params,
               scope: socket.assigns.current_scope
             }),
           {:ok, updated_milestone} when not is_nil(updated_milestone) <-
             get_milestone(socket.assigns.milestone.id, socket.assigns.current_scope) do
        send(self(), {:show_flash, :info, "Task updated successfully"})

        {:noreply,
         socket
         |> assign(:milestone, updated_milestone)
         |> assign(:editing_task, nil)
         |> assign(:task_form, nil)}
      else
        {:error, %Ecto.Changeset{} = changeset} ->
          {:noreply, assign(socket, :task_form, to_form(changeset))}

        _ ->
          send(self(), {:show_flash, :error, "Failed to reload milestone"})
          {:noreply, socket}
      end
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
        # Reload the milestone with updated tasks
        case get_milestone(socket.assigns.milestone.id, socket.assigns.current_scope) do
          {:ok, updated_milestone} when not is_nil(updated_milestone) ->
            send(self(), {:show_flash, :info, "Task completed!"})
            {:noreply, assign(socket, :milestone, updated_milestone)}

          _ ->
            send(self(), {:show_flash, :error, "Failed to reload milestone"})
            {:noreply, socket}
        end

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
        # Reload the milestone with updated tasks
        case get_milestone(socket.assigns.milestone.id, socket.assigns.current_scope) do
          {:ok, updated_milestone} when not is_nil(updated_milestone) ->
            send(self(), {:show_flash, :info, "Task deleted successfully"})
            {:noreply, assign(socket, :milestone, updated_milestone)}

          _ ->
            send(self(), {:show_flash, :error, "Failed to reload milestone"})
            {:noreply, socket}
        end

      {:error, _} ->
        send(self(), {:show_flash, :error, "Failed to delete task"})
        {:noreply, socket}
    end
  end

  def handle_event("cancel", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/project/#{socket.assigns.project.id}/milestones")}
  end

  def handle_event("validate", params, socket) do
    case params do
      # If this is a task field change (nested form)
      %{"_target" => ["task" | _], "task" => task_params} ->
        validate_task(socket, task_params)

      # Regular milestone validation
      %{"milestone" => milestone_params} ->
        validate_milestone(socket, milestone_params)

      # Fallback
      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("save", params, socket) do
    case params do
      # If both milestone and task data are present (task being edited)
      %{"milestone" => milestone_params, "task" => task_params} ->
        save_milestone_with_task(socket, milestone_params, task_params)

      # Only milestone data (regular save)
      %{"milestone" => milestone_params} ->
        save_milestone_only(socket, milestone_params)

      # Fallback
      _ ->
        {:noreply, socket}
    end
  end

  defp validate_task(socket, task_params) do
    task_id = socket.assigns.editing_task

    if task_id do
      validate_existing_task(socket, task_id, task_params)
    else
      {:noreply, socket}
    end
  end

  defp validate_existing_task(socket, task_id, task_params) do
    task = Enum.find(socket.assigns.milestone.tasks, &(&1.id == task_id))

    if task do
      changeset =
        task
        |> WeCraft.Milestones.Task.changeset(task_params)
        |> Map.put(:action, :validate)

      {:noreply, assign(socket, :task_form, to_form(changeset))}
    else
      {:noreply, socket}
    end
  end

  defp validate_milestone(socket, milestone_params) do
    milestone_params = Map.put(milestone_params, "project_id", socket.assigns.project.id)

    changeset =
      socket.assigns.milestone
      |> Milestone.changeset(milestone_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, changeset: changeset, form: to_form(changeset))}
  end

  defp save_milestone_with_task(socket, milestone_params, task_params) do
    milestone_params = Map.put(milestone_params, "project_id", socket.assigns.project.id)
    task_id = socket.assigns.editing_task

    if task_id do
      update_task_then_milestone(socket, task_id, task_params, milestone_params)
    else
      save_milestone_only(socket, milestone_params)
    end
  end

  defp update_task_then_milestone(socket, task_id, task_params, milestone_params) do
    case Milestones.update_task(%{
           task_id: task_id,
           attrs: task_params,
           scope: socket.assigns.current_scope
         }) do
      {:ok, _task} ->
        update_milestone_after_task_success(socket, milestone_params)

      {:error, %Ecto.Changeset{} = task_changeset} ->
        {:noreply, assign(socket, :task_form, to_form(task_changeset))}

      {:error, :unauthorized} ->
        {:noreply,
         socket
         |> put_flash(:error, "You don't have permission to edit this task")}
    end
  end

  defp update_milestone_after_task_success(socket, milestone_params) do
    case Milestones.update_milestone(%{
           milestone_id: socket.assigns.milestone.id,
           attrs: milestone_params,
           scope: socket.assigns.current_scope
         }) do
      {:ok, milestone} ->
        {:noreply,
         socket
         |> put_flash(
           :info,
           "Milestone \"#{milestone.title}\" and task updated successfully!"
         )
         |> push_navigate(to: ~p"/project/#{socket.assigns.project.id}/milestones")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset, form: to_form(changeset))}

      {:error, :unauthorized} ->
        {:noreply,
         socket
         |> put_flash(:error, "You don't have permission to edit this milestone")
         |> push_navigate(to: ~p"/project/#{socket.assigns.project.id}/milestones")}
    end
  end

  defp save_milestone_only(socket, milestone_params) do
    milestone_params = Map.put(milestone_params, "project_id", socket.assigns.project.id)

    case Milestones.update_milestone(%{
           milestone_id: socket.assigns.milestone.id,
           attrs: milestone_params,
           scope: socket.assigns.current_scope
         }) do
      {:ok, milestone} ->
        {:noreply,
         socket
         |> put_flash(:info, "Milestone \"#{milestone.title}\" updated successfully!")
         |> push_navigate(to: ~p"/project/#{socket.assigns.project.id}/milestones")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset, form: to_form(changeset))}

      {:error, :unauthorized} ->
        {:noreply,
         socket
         |> put_flash(:error, "You don't have permission to edit this milestone")
         |> push_navigate(to: ~p"/project/#{socket.assigns.project.id}/milestones")}
    end
  end

  def handle_info({:show_flash, kind, message}, socket) do
    {:noreply, put_flash(socket, kind, message)}
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
    {:noreply, push_navigate(socket, to: ~p"/project/#{socket.assigns.project.id}/milestones")}
  end

  def handle_info(:open_new_channel_modal, socket) do
    {:noreply, push_navigate(socket, to: ~p"/project/#{socket.assigns.project.id}")}
  end

  defp get_milestone(milestone_id, scope) do
    # We'll use the milestones context to get and verify permissions
    case Milestones.get_milestone(%{milestone_id: milestone_id, scope: scope}) do
      {:ok, milestone} -> {:ok, milestone}
      {:error, reason} -> {:error, reason}
    end
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
          pages={@pages}
          id="left-menu"
          project={@project}
          current_scope={@current_scope}
          current_section={@current_section}
          chats={@chats}
          current_chat={@current_chat}
          active_milestones={@active_milestones}
        />
        
    <!-- Main Content Area -->
        <div class="flex-1 flex flex-col">
          <!-- Header -->
          <div class="p-6 border-b border-base-200 bg-base-100">
            <div class="flex items-center justify-between">
              <div>
                <h1 class="text-2xl font-bold text-base-content">Edit Milestone</h1>
                <p class="text-base-content/70 mt-1">
                  Update milestone for <span class="font-medium">{@project.title}</span>
                </p>
              </div>
              <.link navigate={~p"/project/#{@project.id}/milestones"} class="btn btn-ghost btn-sm">
                <.icon name="hero-x-mark" class="w-4 h-4 mr-2" /> Cancel
              </.link>
            </div>
          </div>
          
    <!-- Form Content -->
          <div class="flex-1 overflow-y-auto">
            <div class="mx-auto p-6">
              <div class="card bg-base-100 shadow-lg">
                <div class="card-body">
                  <.form for={@form} phx-change="validate" phx-submit="save" class="space-y-6">
                    <!-- Title Field -->
                    <div class="form-control">
                      <label class="label">
                        <span class="label-text font-medium">
                          Title <span class="text-error">*</span>
                        </span>
                      </label>
                      <.input
                        field={@form[:title]}
                        type="text"
                        placeholder="Enter milestone title..."
                        class="input input-bordered w-full"
                        required
                      />
                    </div>
                    
    <!-- Description Field -->
                    <div class="form-control">
                      <label class="label">
                        <span class="label-text font-medium">
                          Description <span class="text-error">*</span>
                        </span>
                      </label>
                      <.input
                        field={@form[:description]}
                        type="textarea"
                        placeholder="Describe this milestone and what needs to be accomplished..."
                        class="textarea textarea-bordered w-full h-32"
                        required
                      />
                    </div>
                    
    <!-- Status and Due Date Row -->
                    <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                      <!-- Status Field -->
                      <div class="form-control">
                        <label class="label">
                          <span class="label-text font-medium">
                            Status <span class="text-error">*</span>
                          </span>
                        </label>
                        <.input
                          field={@form[:status]}
                          type="select"
                          options={[
                            {"Planned", "planned"},
                            {"Active", "active"},
                            {"Completed", "completed"}
                          ]}
                          class="select select-bordered w-full"
                          required
                        />
                      </div>
                      
    <!-- Due Date Field -->
                      <div class="form-control">
                        <label class="label">
                          <span class="label-text font-medium">Due Date</span>
                          <span class="label-text-alt text-base-content/60">Optional</span>
                        </label>
                        <.input
                          field={@form[:due_date]}
                          type="datetime-local"
                          class="input input-bordered w-full"
                        />
                      </div>
                    </div>
                    
    <!-- Tasks Section -->
                    <div class="form-control">
                      <label class="label">
                        <span class="label-text font-medium">Tasks</span>
                        <button type="button" phx-click="add-task" class="btn btn-ghost btn-xs">
                          <.icon name="hero-plus" class="w-3 h-3 mr-1" /> Add Task
                        </button>
                      </label>

                      <%= if Enum.empty?(@milestone.tasks) do %>
                        <p class="text-sm text-base-content/50 italic text-center py-4">
                          No tasks yet. Click "Add Task" to create the first task for this milestone.
                        </p>
                      <% else %>
                        <div class="space-y-2">
                          <%= for task <- @milestone.tasks do %>
                            <%= if @editing_task == task.id do %>
                              <!-- Editing form -->
                              <div class="p-3 bg-base-50 rounded-lg border border-base-200">
                                <.form
                                  for={@task_form}
                                  phx-submit="save-task"
                                  phx-change="validate-task"
                                >
                                  <div class="grid grid-cols-1 gap-3">
                                    <div>
                                      <.input
                                        field={@task_form[:title]}
                                        type="text"
                                        placeholder="Task title"
                                        class="input input-sm input-bordered w-full"
                                      />
                                    </div>
                                    <div>
                                      <.input
                                        field={@task_form[:description]}
                                        type="textarea"
                                        placeholder="Task description"
                                        class="textarea textarea-sm textarea-bordered w-full h-20"
                                      />
                                    </div>
                                    <div class="grid grid-cols-2 gap-3">
                                      <div>
                                        <.input
                                          field={@task_form[:status]}
                                          type="select"
                                          options={[
                                            {"Planned", "planned"},
                                            {"Active", "active"},
                                            {"Completed", "completed"}
                                          ]}
                                          class="select select-sm select-bordered w-full"
                                        />
                                      </div>
                                      <div class="flex gap-2 justify-end">
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
                                          Save
                                        </button>
                                      </div>
                                    </div>
                                  </div>
                                </.form>
                              </div>
                            <% else %>
                              <!-- Display mode -->
                              <div class="flex items-center justify-between p-3 bg-base-50 rounded-lg border border-base-200 hover:bg-base-100 transition-colors">
                                <div class="flex items-center gap-3 flex-1">
                                  <div class={
                                      "w-3 h-3 rounded-full #{task_status_color(task.status)}"
                                    }>
                                  </div>
                                  <div class="flex-1 min-w-0">
                                    <p class="text-sm font-medium text-base-content truncate">
                                      {task.title}
                                    </p>
                                    <p class="text-xs text-base-content/60 truncate">
                                      {task.description}
                                    </p>
                                  </div>
                                  <span class={
                                      "badge badge-sm #{task_status_badge_class(task.status)}"
                                    }>
                                    {format_task_status(task.status)}
                                  </span>
                                </div>
                                <div class="flex items-center gap-1 ml-3">
                                  <button
                                    type="button"
                                    phx-click="edit-task"
                                    phx-value-task-id={task.id}
                                    class="btn btn-ghost btn-sm text-base-content/60 hover:text-base-content"
                                    title="Edit task"
                                  >
                                    <.icon name="hero-pencil" class="w-4 h-4" />
                                  </button>
                                  <%= if task.status != :completed do %>
                                    <button
                                      type="button"
                                      phx-click="complete-task"
                                      phx-value-task-id={task.id}
                                      class="btn btn-ghost btn-sm text-success"
                                      title="Mark as completed"
                                    >
                                      <.icon name="hero-check" class="w-4 h-4" />
                                    </button>
                                  <% end %>
                                  <button
                                    type="button"
                                    phx-click="delete-task"
                                    phx-value-task-id={task.id}
                                    class="btn btn-ghost btn-sm text-error"
                                    title="Delete task"
                                  >
                                    <.icon name="hero-trash" class="w-4 h-4" />
                                  </button>
                                </div>
                              </div>
                            <% end %>
                          <% end %>
                        </div>
                      <% end %>
                    </div>
                    
    <!-- Action Buttons -->
                    <div class="flex justify-end gap-4 pt-6 border-t border-base-200">
                      <button type="button" phx-click="cancel" class="btn btn-ghost">
                        Cancel
                      </button>
                      <button type="submit" class="btn btn-primary" disabled={!@form.source.valid?}>
                        <.icon name="hero-check" class="w-4 h-4 mr-2" /> Update Milestone
                      </button>
                    </div>
                  </.form>
                </div>
              </div>
              
    <!-- Help Section -->
              <div class="mt-8 card bg-base-100 shadow-sm">
                <div class="card-body">
                  <h3 class="card-title text-lg">
                    <.icon name="hero-lightbulb" class="w-5 h-5 text-warning" />
                    Tips for Updating Milestones
                  </h3>
                  <div class="space-y-3 text-sm text-base-content/80">
                    <div class="flex gap-3">
                      <div class="w-2 h-2 bg-primary rounded-full mt-2 flex-shrink-0"></div>
                      <p>
                        <strong>Update Status:</strong>
                        Change the status to reflect current progress - from planned to active to completed.
                      </p>
                    </div>
                    <div class="flex gap-3">
                      <div class="w-2 h-2 bg-primary rounded-full mt-2 flex-shrink-0"></div>
                      <p>
                        <strong>Adjust Dates:</strong>
                        Update due dates based on new information or changed requirements.
                      </p>
                    </div>
                    <div class="flex gap-3">
                      <div class="w-2 h-2 bg-primary rounded-full mt-2 flex-shrink-0"></div>
                      <p>
                        <strong>Refine Description:</strong>
                        Update the description to reflect any changes in scope or requirements.
                      </p>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp get_active_milestones(project_id, scope) do
    case Milestones.list_project_milestones(%{project_id: project_id, scope: scope}) do
      {:ok, milestones} ->
        milestones
        |> Enum.filter(&(&1.status == :active))

      {:error, _} ->
        []
    end
  end
end
