defmodule WeCraft.Projects.UseCases.ListProjectEventsUseCase do
  @moduledoc """
  Use case for listing events related to a specific project.
  This module provides functionality to retrieve all events associated with a given project.
  """
  alias WeCraft.Projects.Infrastructure.Ecto.ProjectEventsRepositoryEcto

  def list_project_events(%{project_id: project_id}) do
    {:ok, ProjectEventsRepositoryEcto.get_events_for_project(project_id)}
  end
end
