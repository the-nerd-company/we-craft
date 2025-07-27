defmodule WeCraft.Projects.UseCases.CheckFollowingStatusUseCase do
  @moduledoc """
  Use case for checking if a user is following a project.
  """

  alias WeCraft.Projects.Infrastructure.Ecto.FollowerRepositoryEcto

  def check_following_status(%{user_id: user_id, project_id: project_id}) do
    {:ok, FollowerRepositoryEcto.following?(user_id, project_id)}
  end
end
