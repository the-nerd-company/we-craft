defmodule WeCraft.Projects.Infrastructure.Ecto.FollowerRepositoryEcto do
  @moduledoc """
  Ecto repository for follower operations.
  """

  import Ecto.Query, warn: false

  alias WeCraft.Projects.Follower
  alias WeCraft.Repo

  @doc """
  Creates a follower relationship.
  """
  def follow_project(attrs) do
    %Follower{}
    |> Follower.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Removes a follower relationship.
  """
  def unfollow_project(user_id, project_id) do
    from(f in Follower, where: f.user_id == ^user_id and f.project_id == ^project_id)
    |> Repo.delete_all()
    |> case do
      {1, _} -> {:ok, :unfollowed}
      {0, _} -> {:error, :not_following}
    end
  end

  @doc """
  Checks if a user is following a project.
  """
  def following?(user_id, project_id) do
    from(f in Follower, where: f.user_id == ^user_id and f.project_id == ^project_id)
    |> Repo.exists?()
  end

  @doc """
  Gets all followers of a project.
  """
  def get_project_followers(project_id) do
    from(f in Follower,
      where: f.project_id == ^project_id,
      preload: [:user]
    )
    |> Repo.all()
  end

  @doc """
  Gets all projects followed by a user.
  """
  def get_user_following(user_id) do
    from(f in Follower,
      where: f.user_id == ^user_id,
      preload: [:project]
    )
    |> Repo.all()
  end

  @doc """
  Gets the count of followers for a project.
  """
  def get_followers_count(project_id) do
    from(f in Follower, where: f.project_id == ^project_id)
    |> Repo.aggregate(:count, :id)
  end
end
