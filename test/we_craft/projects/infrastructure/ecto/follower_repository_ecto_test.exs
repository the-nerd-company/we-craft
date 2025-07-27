defmodule WeCraft.Projects.Infrastructure.Ecto.FollowerRepositoryEctoTest do
  @moduledoc """
  Tests for the FollowerRepositoryEcto module.
  """
  use WeCraft.DataCase

  alias WeCraft.Projects.Follower
  alias WeCraft.Projects.Infrastructure.Ecto.FollowerRepositoryEcto

  describe "follow_project/1" do
    setup do
      user = WeCraft.AccountsFixtures.user_fixture()
      project = WeCraft.ProjectsFixtures.project_fixture()

      %{user: user, project: project}
    end

    test "creates a follower relationship", %{user: user, project: project} do
      attrs = %{user_id: user.id, project_id: project.id}

      assert {:ok, %Follower{} = follower} = FollowerRepositoryEcto.follow_project(attrs)
      assert follower.user_id == user.id
      assert follower.project_id == project.id
    end

    test "prevents duplicate follows", %{user: user, project: project} do
      attrs = %{user_id: user.id, project_id: project.id}

      # First follow should succeed
      assert {:ok, _follower} = FollowerRepositoryEcto.follow_project(attrs)

      # Second follow should fail due to unique constraint
      assert {:error, changeset} = FollowerRepositoryEcto.follow_project(attrs)
      assert changeset.errors[:user_id] || changeset.errors[:project_id]
    end
  end

  describe "unfollow_project/2" do
    setup do
      user = WeCraft.AccountsFixtures.user_fixture()
      project = WeCraft.ProjectsFixtures.project_fixture()

      %{user: user, project: project}
    end

    test "removes a follower relationship", %{user: user, project: project} do
      # First create a follow relationship
      attrs = %{user_id: user.id, project_id: project.id}
      {:ok, _follower} = FollowerRepositoryEcto.follow_project(attrs)

      # Then unfollow
      assert {:ok, :unfollowed} = FollowerRepositoryEcto.unfollow_project(user.id, project.id)

      # Verify the relationship was removed
      refute FollowerRepositoryEcto.following?(user.id, project.id)
    end

    test "returns error when not following", %{user: user, project: project} do
      assert {:error, :not_following} =
               FollowerRepositoryEcto.unfollow_project(user.id, project.id)
    end
  end

  describe "following?/2" do
    setup do
      user = WeCraft.AccountsFixtures.user_fixture()
      project = WeCraft.ProjectsFixtures.project_fixture()

      %{user: user, project: project}
    end

    test "returns true when user is following project", %{user: user, project: project} do
      attrs = %{user_id: user.id, project_id: project.id}
      {:ok, _follower} = FollowerRepositoryEcto.follow_project(attrs)

      assert FollowerRepositoryEcto.following?(user.id, project.id)
    end

    test "returns false when user is not following project", %{user: user, project: project} do
      refute FollowerRepositoryEcto.following?(user.id, project.id)
    end
  end

  describe "get_project_followers/1" do
    setup do
      user1 = WeCraft.AccountsFixtures.user_fixture()
      user2 = WeCraft.AccountsFixtures.user_fixture()
      project = WeCraft.ProjectsFixtures.project_fixture()

      %{user1: user1, user2: user2, project: project}
    end

    test "returns all followers of a project", %{user1: user1, user2: user2, project: project} do
      # Create follow relationships
      {:ok, _} =
        FollowerRepositoryEcto.follow_project(%{user_id: user1.id, project_id: project.id})

      {:ok, _} =
        FollowerRepositoryEcto.follow_project(%{user_id: user2.id, project_id: project.id})

      followers = FollowerRepositoryEcto.get_project_followers(project.id)

      assert length(followers) == 2
      user_ids = Enum.map(followers, fn f -> f.user.id end)
      assert user1.id in user_ids
      assert user2.id in user_ids
    end

    test "returns empty list when project has no followers", %{project: project} do
      followers = FollowerRepositoryEcto.get_project_followers(project.id)
      assert followers == []
    end
  end

  describe "get_user_following/1" do
    setup do
      user = WeCraft.AccountsFixtures.user_fixture()
      project1 = WeCraft.ProjectsFixtures.project_fixture()
      project2 = WeCraft.ProjectsFixtures.project_fixture()

      %{user: user, project1: project1, project2: project2}
    end

    test "returns all projects followed by a user", %{
      user: user,
      project1: project1,
      project2: project2
    } do
      # Create follow relationships
      {:ok, _} =
        FollowerRepositoryEcto.follow_project(%{user_id: user.id, project_id: project1.id})

      {:ok, _} =
        FollowerRepositoryEcto.follow_project(%{user_id: user.id, project_id: project2.id})

      following = FollowerRepositoryEcto.get_user_following(user.id)

      assert length(following) == 2
      project_ids = Enum.map(following, fn f -> f.project.id end)
      assert project1.id in project_ids
      assert project2.id in project_ids
    end

    test "returns empty list when user is not following any projects", %{user: user} do
      following = FollowerRepositoryEcto.get_user_following(user.id)
      assert following == []
    end
  end

  describe "get_followers_count/1" do
    setup do
      user1 = WeCraft.AccountsFixtures.user_fixture()
      user2 = WeCraft.AccountsFixtures.user_fixture()
      project = WeCraft.ProjectsFixtures.project_fixture()

      %{user1: user1, user2: user2, project: project}
    end

    test "returns correct follower count", %{user1: user1, user2: user2, project: project} do
      # Initially no followers
      assert FollowerRepositoryEcto.get_followers_count(project.id) == 0

      # Add one follower
      {:ok, _} =
        FollowerRepositoryEcto.follow_project(%{user_id: user1.id, project_id: project.id})

      assert FollowerRepositoryEcto.get_followers_count(project.id) == 1

      # Add another follower
      {:ok, _} =
        FollowerRepositoryEcto.follow_project(%{user_id: user2.id, project_id: project.id})

      assert FollowerRepositoryEcto.get_followers_count(project.id) == 2
    end
  end
end
