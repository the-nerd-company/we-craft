defmodule WeCraft.Projects.UseCases.GetProjectFollowersCountUseCaseTest do
  @moduledoc """
  Tests for the GetProjectFollowersCountUseCase module.
  """
  use WeCraft.DataCase

  alias WeCraft.Projects.UseCases.{FollowProjectUseCase, GetProjectFollowersCountUseCase}

  import WeCraft.AccountsFixtures
  import WeCraft.ProjectsFixtures

  describe "get_project_followers_count/1" do
    setup do
      user1 = user_fixture()
      user2 = user_fixture()
      project = project_fixture()

      %{user1: user1, user2: user2, project: project}
    end

    test "returns 0 when project has no followers", %{project: project} do
      assert {:ok, 0} =
               GetProjectFollowersCountUseCase.get_project_followers_count(%{
                 project_id: project.id
               })
    end

    test "returns correct count when project has followers", %{
      user1: user1,
      user2: user2,
      project: project
    } do
      # Initially no followers
      assert {:ok, 0} =
               GetProjectFollowersCountUseCase.get_project_followers_count(%{
                 project_id: project.id
               })

      # Add one follower
      {:ok, _} = FollowProjectUseCase.follow_project(%{user_id: user1.id, project_id: project.id})

      assert {:ok, 1} =
               GetProjectFollowersCountUseCase.get_project_followers_count(%{
                 project_id: project.id
               })

      # Add another follower
      {:ok, _} = FollowProjectUseCase.follow_project(%{user_id: user2.id, project_id: project.id})

      assert {:ok, 2} =
               GetProjectFollowersCountUseCase.get_project_followers_count(%{
                 project_id: project.id
               })
    end
  end
end
