defmodule WeCraftWeb.Projects.Milestones.NewMilestone do
  @moduledoc """
  LiveView for creating a new milestone for a project.
  """
  use WeCraftWeb, :live_view

  alias WeCraft.{Milestones, Pages, Projects}
  alias WeCraft.Milestones.Milestone
  alias WeCraftWeb.Components.LeftMenu

  def mount(%{"project_id" => project_id}, _session, socket) do
    project_id = String.to_integer(project_id)
    scope = socket.assigns.current_scope

    case Projects.get_project(%{project_id: project_id, scope: scope}) do
      {:ok, nil} ->
        {:ok, push_navigate(socket, to: ~p"/")}

      {:ok, project} ->
        # Get chats for the left menu
        {:ok, chats} = WeCraft.Chats.list_project_chats(%{project_id: project.id})
        {:ok, pages} = Pages.list_project_pages(%{project: project, scope: scope})

        # Get active milestones for the left menu
        active_milestones = get_active_milestones(project.id, scope)

        changeset = Milestone.changeset(%Milestone{}, %{})

        {:ok,
         socket
         |> assign(:project, project)
         |> assign(:chats, chats)
         |> assign(:current_chat, nil)
         |> assign(:current_section, :milestones)
         |> assign(:active_milestones, active_milestones)
         |> assign(:changeset, changeset)
         |> assign(:pages, pages)
         |> assign(:form, to_form(changeset))
         |> assign(:page_title, "New Milestone - #{project.title}")
         |> assign(:form_errors, [])}
    end
  end

  def handle_event("validate", %{"milestone" => milestone_params}, socket) do
    milestone_params = Map.put(milestone_params, "project_id", socket.assigns.project.id)

    changeset =
      %Milestone{}
      |> Milestone.changeset(milestone_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, changeset: changeset, form: to_form(changeset))}
  rescue
    _error ->
      {:noreply, socket}
  end

  def handle_event("save", %{"milestone" => milestone_params}, socket) do
    milestone_params = Map.put(milestone_params, "project_id", socket.assigns.project.id)

    case Milestones.create_milestone(%{
           attrs: milestone_params,
           scope: socket.assigns.current_scope
         }) do
      {:ok, milestone} ->
        {:noreply,
         socket
         |> put_flash(:info, "Milestone \"#{milestone.title}\" created successfully!")
         |> push_navigate(to: ~p"/project/#{socket.assigns.project.id}/milestones")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset, form: to_form(changeset))}
    end
  end

  def handle_event("cancel", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/project/#{socket.assigns.project.id}/milestones")}
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
        <div class="flex-1 flex flex-col">
          <!-- Header -->
          <div class="p-6 border-b border-base-200 bg-base-100">
            <div class="flex items-center justify-between">
              <div>
                <h1 class="text-2xl font-bold text-base-content">Create New Milestone</h1>
                <p class="text-base-content/70 mt-1">
                  Add a new milestone to track progress for
                  <span class="font-medium">{@project.title}</span>
                </p>
              </div>
              <.link navigate={~p"/project/#{@project.id}/milestones"} class="btn btn-ghost btn-sm">
                <.icon name="hero-x-mark" class="w-4 h-4 mr-2" /> Cancel
              </.link>
            </div>
          </div>
          
    <!-- Form Content -->
          <div class="flex-1 overflow-y-auto">
            <div class="max-w-2xl mx-auto p-6">
              <div class="card bg-base-100 shadow-lg">
                <div class="card-body">
                  <.form
                    for={@form}
                    phx-change="validate"
                    phx-submit="save"
                    class="space-y-6"
                    id="new-milestone-form"
                  >
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
                        class="textarea textarea-bordered w-full min-h-32 resize-y overflow-y-auto"
                        style="max-height: 200px;"
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
                    
    <!-- Action Buttons -->
                    <div class="flex justify-end gap-4 pt-6 border-t border-base-200">
                      <button type="button" phx-click="cancel" class="btn btn-ghost">
                        Cancel
                      </button>
                      <button type="submit" class="btn btn-primary" disabled={!@form.source.valid?}>
                        <.icon name="hero-flag" class="w-4 h-4 mr-2" /> Create Milestone
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
                    Tips for Creating Effective Milestones
                  </h3>
                  <div class="space-y-3 text-sm text-base-content/80">
                    <div class="flex gap-3">
                      <div class="w-2 h-2 bg-primary rounded-full mt-2 flex-shrink-0"></div>
                      <p>
                        <strong>Be Specific:</strong>
                        Use clear, actionable titles that describe exactly what needs to be accomplished.
                      </p>
                    </div>
                    <div class="flex gap-3">
                      <div class="w-2 h-2 bg-primary rounded-full mt-2 flex-shrink-0"></div>
                      <p>
                        <strong>Set Realistic Dates:</strong>
                        Choose due dates that are challenging but achievable for your team.
                      </p>
                    </div>
                    <div class="flex gap-3">
                      <div class="w-2 h-2 bg-primary rounded-full mt-2 flex-shrink-0"></div>
                      <p>
                        <strong>Break Down Large Goals:</strong>
                        Complex objectives should be split into smaller, manageable milestones.
                      </p>
                    </div>
                    <div class="flex gap-3">
                      <div class="w-2 h-2 bg-primary rounded-full mt-2 flex-shrink-0"></div>
                      <p>
                        <strong>Track Progress:</strong>
                        Use the status field to keep everyone updated on milestone progress.
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
