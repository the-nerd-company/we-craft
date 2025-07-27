defmodule WeCraft.Projects.UseCases.FollowProjectUseCase do
  @moduledoc """
  Use case for following a project.
  """

  alias WeCraft.Projects.Infrastructure.Ecto.FollowerRepositoryEcto

  def follow_project(%{user_id: user_id, project_id: project_id}) do
    case FollowerRepositoryEcto.following?(user_id, project_id) do
      true ->
        {:error, :already_following}

      false ->
        FollowerRepositoryEcto.follow_project(%{user_id: user_id, project_id: project_id})
    end
  end
end
