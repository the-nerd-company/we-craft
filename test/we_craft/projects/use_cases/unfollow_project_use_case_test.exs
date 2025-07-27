defmodule WeCraft.Projects.UseCases.UnfollowProjectUseCaseTest do
  @moduledoc """
  Tests for the UnfollowProjectUseCase module.
  """
  use WeCraft.DataCase

  alias WeCraft.Projects.UseCases.{FollowProjectUseCase, UnfollowProjectUseCase}

  import WeCraft.AccountsFixtures
  import WeCraft.ProjectsFixtures

  describe "unfollow_project/1" do
    setup do
      user = user_fixture()
      project = project_fixture()

      %{user: user, project: project}
    end

    test "successfully unfollows a project", %{user: user, project: project} do
      attrs = %{user_id: user.id, project_id: project.id}

      # First follow the project
      {:ok, _follower} = FollowProjectUseCase.follow_project(attrs)

      # Then unfollow
      assert {:ok, :unfollowed} = UnfollowProjectUseCase.unfollow_project(attrs)
    end

    test "returns error when not following", %{user: user, project: project} do
      attrs = %{user_id: user.id, project_id: project.id}

      assert {:error, :not_following} = UnfollowProjectUseCase.unfollow_project(attrs)
    end
  end
end
