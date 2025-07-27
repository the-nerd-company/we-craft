defmodule WeCraft.Projects.UseCases.FollowProjectUseCaseTest do
  @moduledoc """
  Tests for the FollowProjectUseCase module.
  """
  use WeCraft.DataCase

  alias WeCraft.Projects.UseCases.FollowProjectUseCase

  import WeCraft.AccountsFixtures
  import WeCraft.ProjectsFixtures

  describe "follow_project/1" do
    setup do
      user = user_fixture()
      project = project_fixture()

      %{user: user, project: project}
    end

    test "successfully follows a project", %{user: user, project: project} do
      attrs = %{user_id: user.id, project_id: project.id}

      assert {:ok, _follower} = FollowProjectUseCase.follow_project(attrs)
    end

    test "returns error when already following", %{user: user, project: project} do
      attrs = %{user_id: user.id, project_id: project.id}

      # First follow should succeed
      assert {:ok, _follower} = FollowProjectUseCase.follow_project(attrs)

      # Second follow should return error
      assert {:error, :already_following} = FollowProjectUseCase.follow_project(attrs)
    end
  end
end
