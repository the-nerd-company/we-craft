defmodule WeCraftWeb.Projects.NewProject do
  @moduledoc """
  LiveView for creating a new project.
  """
  use WeCraftWeb, :live_view

  alias WeCraft.Projects
  alias WeCraft.Projects.Project
  alias WeCraftWeb.Projects.Components.ProjectFormComponent

  def mount(_params, _session, socket) do
    changeset = Project.changeset(%Project{}, %{})

    socket =
      socket
      |> assign(:changeset, changeset)

    {:ok, socket}
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

  def handle_event("new-project-form-save", %{"project" => project_params}, socket) do
    # Add the owner_id to the project params
    project_params = Map.put(project_params, "owner_id", socket.assigns.current_scope.user.id)

    case Projects.create_project(%{attrs: project_params}) do
      {:ok, project} ->
        {:noreply,
         socket
         |> put_flash(:info, "Project created successfully!")
         |> redirect(to: ~p"/project/#{project.id}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  def handle_info({:save_project, project_params}, socket) do
    # Add the owner_id to the project params
    project_params = Map.put(project_params, "owner_id", socket.assigns.current_scope.user.id)

    case Projects.create_project(%{attrs: project_params}) do
      {:ok, project} ->
        {:noreply,
         socket
         |> put_flash(:info, "Project created successfully!")
         |> redirect(to: ~p"/project/#{project.id}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end
end
