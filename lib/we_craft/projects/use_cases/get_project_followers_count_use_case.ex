defmodule WeCraft.Projects.UseCases.GetProjectFollowersCountUseCase do
  @moduledoc """
  Use case for getting the follower count of a project.
  """

  alias WeCraft.Projects.Infrastructure.Ecto.FollowerRepositoryEcto

  def get_project_followers_count(%{project_id: project_id}) do
    {:ok, FollowerRepositoryEcto.get_followers_count(project_id)}
  end
end
