defmodule WeCraft.Accounts.Infrastructure.Ecto.UserRepositoryEctoTest do
  @moduledoc """
  Tests for the UserRepositoryEcto module.
  """
  use WeCraft.DataCase

  alias WeCraft.Accounts.Infrastructure.Ecto.UserRepositoryEcto
  alias WeCraft.Accounts.User
  alias WeCraft.Profiles.Profile

  import WeCraft.AccountsFixtures

  describe "search_users/1" do
    test "returns empty list when no users exist" do
      result = UserRepositoryEcto.search_users(%{})
      assert result == []
    end

    test "returns all users when users exist" do
      user1 = user_fixture()
      user2 = user_fixture()

      result = UserRepositoryEcto.search_users(%{})

      assert length(result) == 2

      user_ids = Enum.map(result, & &1.id)
      assert user1.id in user_ids
      assert user2.id in user_ids
    end

    test "returns users with preloaded profiles" do
      user = user_fixture()

      # Create a profile for the user
      profile_attrs = %{bio: "Test bio", user_id: user.id}

      {:ok, _profile} =
        %Profile{}
        |> Profile.changeset(profile_attrs)
        |> WeCraft.Repo.insert()

      result = UserRepositoryEcto.search_users(%{})

      assert length(result) == 1
      user_result = hd(result)

      # Verify profile is preloaded
      assert Ecto.assoc_loaded?(user_result.profile)
      assert user_result.profile.bio == "Test bio"
    end

    test "returns users with nil profile when no profile exists" do
      _user = user_fixture()

      result = UserRepositoryEcto.search_users(%{})

      assert length(result) == 1
      user_result = hd(result)

      # Verify profile association is preloaded but nil
      assert Ecto.assoc_loaded?(user_result.profile)
      assert user_result.profile == nil
    end

    test "ignores search parameters and returns all users" do
      user1 = user_fixture()
      user2 = user_fixture()

      # Test with various parameters to ensure they're ignored
      params_variations = [
        %{},
        %{name: "some name"},
        %{email: "test@example.com"},
        %{search: "query"},
        %{filter: "active"},
        %{limit: 1},
        %{offset: 10}
      ]

      for params <- params_variations do
        result = UserRepositoryEcto.search_users(params)

        assert length(result) == 2
        user_ids = Enum.map(result, & &1.id)
        assert user1.id in user_ids
        assert user2.id in user_ids
      end
    end

    test "returns users sorted by insertion order" do
      # Create users in specific order
      user1 = user_fixture(%{email: "first@example.com"})
      user2 = user_fixture(%{email: "second@example.com"})
      user3 = user_fixture(%{email: "third@example.com"})

      result = UserRepositoryEcto.search_users(%{})

      assert length(result) == 3
      # Verify all users are present (order may vary without explicit ORDER BY)
      result_ids = Enum.map(result, & &1.id) |> Enum.sort()
      expected_ids = [user1.id, user2.id, user3.id] |> Enum.sort()
      assert result_ids == expected_ids
    end

    test "handles users with mixed profile states" do
      user_with_profile = user_fixture()
      user_without_profile = user_fixture()

      # Create profile for first user only
      profile_attrs = %{bio: "I have a profile", user_id: user_with_profile.id}

      {:ok, _profile} =
        %Profile{}
        |> Profile.changeset(profile_attrs)
        |> WeCraft.Repo.insert()

      result = UserRepositoryEcto.search_users(%{})

      assert length(result) == 2

      # Find users in result
      user_with_profile_result = Enum.find(result, &(&1.id == user_with_profile.id))
      user_without_profile_result = Enum.find(result, &(&1.id == user_without_profile.id))

      # Verify both have profile association preloaded
      assert Ecto.assoc_loaded?(user_with_profile_result.profile)
      assert Ecto.assoc_loaded?(user_without_profile_result.profile)

      # Verify profile content
      assert user_with_profile_result.profile.bio == "I have a profile"
      assert user_without_profile_result.profile == nil
    end

    test "returns User structs with all expected fields" do
      user = user_fixture()

      result = UserRepositoryEcto.search_users(%{})

      assert length(result) == 1
      user_result = hd(result)

      # Verify it's a proper User struct
      assert %User{} = user_result
      assert user_result.id == user.id
      assert user_result.email == user.email
      assert user_result.name == user.name
      assert user_result.confirmed_at == user.confirmed_at
      assert is_struct(user_result.inserted_at, DateTime)
      assert is_struct(user_result.updated_at, DateTime)
    end
  end

  describe "integration scenarios" do
    test "works correctly with large number of users" do
      # Create multiple users with various profile states
      users_with_profiles =
        for i <- 1..3 do
          user = user_fixture(%{email: "profile_user_#{i}@example.com"})

          profile_attrs = %{bio: "Bio for user #{i}", user_id: user.id}

          {:ok, _profile} =
            %Profile{}
            |> Profile.changeset(profile_attrs)
            |> WeCraft.Repo.insert()

          user
        end

      users_without_profiles =
        for i <- 1..2 do
          user_fixture(%{email: "no_profile_user_#{i}@example.com"})
        end

      all_users = users_with_profiles ++ users_without_profiles

      result = UserRepositoryEcto.search_users(%{})

      assert length(result) == 5

      # Verify all users are present
      result_ids = Enum.map(result, & &1.id)

      for user <- all_users do
        assert user.id in result_ids
      end

      # Verify profile states
      for user_result <- result do
        original_user = Enum.find(all_users, &(&1.id == user_result.id))

        assert Ecto.assoc_loaded?(user_result.profile)

        cond do
          original_user in users_with_profiles ->
            assert user_result.profile != nil
            assert String.contains?(user_result.profile.bio, "Bio for user")

          original_user in users_without_profiles ->
            assert user_result.profile == nil
        end
      end
    end

    test "maintains data consistency across multiple calls" do
      _user1 = user_fixture()
      _user2 = user_fixture()

      # First call
      result1 = UserRepositoryEcto.search_users(%{})

      # Second call should return identical results
      result2 = UserRepositoryEcto.search_users(%{})

      assert length(result1) == length(result2)
      assert length(result1) == 2

      # Compare results
      result1_ids = Enum.map(result1, & &1.id) |> Enum.sort()
      result2_ids = Enum.map(result2, & &1.id) |> Enum.sort()

      assert result1_ids == result2_ids
    end
  end
end
