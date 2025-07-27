defmodule WeCraft.Projects.UseCases.CheckFollowingStatusUseCaseTest do
  @moduledoc """
  Tests for the CheckFollowingStatusUseCase module.
  """
  use WeCraft.DataCase

  alias WeCraft.Projects.UseCases.{CheckFollowingStatusUseCase, FollowProjectUseCase}

  import WeCraft.AccountsFixtures
  import WeCraft.ProjectsFixtures

  describe "check_following_status/1" do
    setup do
      user = user_fixture()
      project = project_fixture()

      %{user: user, project: project}
    end

    test "returns true when user is following project", %{user: user, project: project} do
      attrs = %{user_id: user.id, project_id: project.id}

      # Follow the project first
      {:ok, _follower} = FollowProjectUseCase.follow_project(attrs)

      assert {:ok, true} = CheckFollowingStatusUseCase.check_following_status(attrs)
    end

    test "returns false when user is not following project", %{user: user, project: project} do
      attrs = %{user_id: user.id, project_id: project.id}

      assert {:ok, false} = CheckFollowingStatusUseCase.check_following_status(attrs)
    end
  end
end
