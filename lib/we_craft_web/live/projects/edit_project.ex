defmodule WeCraftWeb.Projects.EditProject do
  @moduledoc """
  LiveView for editing a project in WeCraft.
  """
  use WeCraftWeb, :live_view

  alias WeCraft.Projects
  alias WeCraft.Projects.Project
  alias WeCraftWeb.Projects.Components.ProjectFormComponent

  def mount(%{"project_id" => project_id}, _session, socket) do
    {:ok, project} =
      Projects.get_project(%{project_id: project_id, scope: socket.assigns.current_scope})

    {:ok,
     socket
     |> assign(:project, project)
     |> assign(:changeset, Project.changeset(project, %{}))}
  end

  def render(assigns) do
    ~H"""
    <div class="new-project-page min-h-screen bg-gradient-to-br from-base-100 to-base-200 p-6">
      <.live_component module={ProjectFormComponent} id="new-project-form" changeset={@changeset} />
    </div>
    """
  end

  def handle_event("new-project-form-validate", %{"project" => project_params}, socket) do
    # Pass the event to the component
    send_update(ProjectFormComponent,
      id: "new-project-form",
      action: :validate,
      project_params: project_params
    )

    {:noreply, socket}
  end

  # Forward any toggle_tag events to the component
  def handle_event("toggle_tag", params, socket) do
    send_update(ProjectFormComponent,
      id: "new-project-form",
      action: :toggle_tag,
      params: params
    )

    {:noreply, socket}
  end

  def handle_info({:save_project, project_params}, socket) do
    # Ensure we're using string keys consistently throughout
    string_params =
      for {key, val} <- project_params, into: %{} do
        {to_string(key), val}
      end

    # Remove the debug output
    {:ok, project} =
      Projects.update_project(%{
        project: socket.assigns.project,
        attrs: string_params
      })

    {:noreply,
     socket
     |> put_flash(:info, "Project updated successfully!")
     |> redirect(to: ~p"/project/#{project.id}")}
  end
end
