defmodule WeCraft.Projects.UseCases.ListUserProjectsUseCase do
  @moduledoc """
  This module provides the use case for listing projects by user.
  """

  alias WeCraft.Projects.Infrastructure.Ecto.ProjectRepositoryEcto

  def list_user_projects(%{user_id: user_id}) do
    {:ok, ProjectRepositoryEcto.list_projects_by_user(user_id)}
  end
end
