defmodule WeCraft.Projects.UseCases.UnfollowProjectUseCase do
  @moduledoc """
  Use case for unfollowing a project.
  """

  alias WeCraft.Projects.Infrastructure.Ecto.FollowerRepositoryEcto

  def unfollow_project(%{user_id: user_id, project_id: project_id}) do
    FollowerRepositoryEcto.unfollow_project(user_id, project_id)
  end
end
