defmodule WeCraft.Projects.UseCases.UpdateProjectUseCase do
  @moduledoc """
  Use case for updating a project.
  """

  alias WeCraft.Projects.Infrastructure.Ecto.{
    ProjectEventsRepositoryEcto,
    ProjectRepositoryEcto
  }

  alias WeCraft.Projects.Project

  def update_project(%{project: %Project{} = project_input, attrs: attrs}) do
    with {:ok, project} <- ProjectRepositoryEcto.update_project(project_input, attrs),
         {:ok, _events} <- create_events(%{project: project, attrs: attrs}) do
      {:ok, project}
    end
  end

  defp create_events(%{project: %Project{} = project_input, attrs: attrs}) do
    {:ok, status_update_event} =
      maybe_create_status_update_event(%{project: project_input, attrs: attrs})

    {:ok, visibility_update_event} =
      maybe_create_visibility_update_event(%{project: project_input, attrs: attrs})

    {:ok, [status_update_event, visibility_update_event] |> Enum.filter(&(&1 != nil))}
  end

  defp maybe_create_status_update_event(%{project: %Project{} = project, attrs: attrs}) do
    if Map.has_key?(attrs, "status") && project.status != attrs["status"] do
      event_attrs = %{
        event_type: "project_status_updated",
        project_id: project.id,
        status: attrs["status"]
      }

      ProjectEventsRepositoryEcto.create_event(event_attrs)
    else
      {:ok, nil}
    end
  end

  defp maybe_create_visibility_update_event(%{project: %Project{} = project, attrs: attrs}) do
    if Map.has_key?(attrs, "visibility") &&
         project.visibility != attrs["visibility"] |> String.to_atom() do
      event_attrs = %{
        event_type: "project_visibility_updated",
        project_id: project.id,
        visibility: attrs["visibility"]
      }

      ProjectEventsRepositoryEcto.create_event(event_attrs)
    else
      {:ok, nil}
    end
  end
end
