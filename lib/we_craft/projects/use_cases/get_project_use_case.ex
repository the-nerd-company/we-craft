defmodule WeCraft.Projects.UseCases.GetProjectUseCase do
  @moduledoc """
  This module provides the use case for getting a specific project by its ID.
  """
  alias WeCraft.Projects.Infrastructure.Ecto.ProjectRepositoryEcto

  def get_project(%{project_id: project_id, scope: _scope}) do
    {:ok, ProjectRepositoryEcto.get_project(project_id)}
  end
end
