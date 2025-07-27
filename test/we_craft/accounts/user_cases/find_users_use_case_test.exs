defmodule WeCraft.Accounts.UserCases.FindUsersUseCaseTest do
  @moduledoc """
  Tests for the FindUsersUseCase module.
  """
  use WeCraft.DataCase, async: true

  alias WeCraft.Accounts
  alias WeCraft.Accounts.{Scope, User}
  alias WeCraft.Profiles.Profile

  import WeCraft.AccountsFixtures

  describe "find_users/1" do
    setup do
      user = user_fixture()
      scope = Scope.for_user(user)

      %{user: user, scope: scope}
    end

    test "returns empty list when no users exist", %{scope: scope} do
      # Delete the user created in setup to have an empty database
      Repo.delete_all(User)

      assert {:ok, []} = Accounts.find_users(%{params: %{}, scope: scope})
    end

    test "returns all users when users exist", %{user: setup_user, scope: scope} do
      # Create additional users
      user1 = user_fixture(%{email: "test1@example.com"})
      user2 = user_fixture(%{email: "test2@example.com"})

      assert {:ok, users} = Accounts.find_users(%{params: %{}, scope: scope})

      assert length(users) == 3
      user_ids = Enum.map(users, & &1.id) |> Enum.sort()
      expected_ids = [setup_user.id, user1.id, user2.id] |> Enum.sort()
      assert user_ids == expected_ids
    end

    test "returns users with preloaded profiles", %{user: user, scope: scope} do
      # Create a profile for the user
      profile_attrs = %{bio: "Test bio for user", user_id: user.id}

      {:ok, _profile} =
        %Profile{}
        |> Profile.changeset(profile_attrs)
        |> Repo.insert()

      assert {:ok, users} = Accounts.find_users(%{params: %{}, scope: scope})

      assert length(users) == 1
      user_result = hd(users)

      # Verify profile is preloaded
      assert Ecto.assoc_loaded?(user_result.profile)
      assert user_result.profile.bio == "Test bio for user"
    end

    test "returns users with nil profile when no profile exists", %{user: _user, scope: scope} do
      assert {:ok, users} = Accounts.find_users(%{params: %{}, scope: scope})

      assert length(users) == 1
      user_result = hd(users)

      # Verify profile association is preloaded but nil
      assert Ecto.assoc_loaded?(user_result.profile)
      assert user_result.profile == nil
    end

    test "ignores params and returns all users", %{user: setup_user, scope: scope} do
      user1 = user_fixture(%{email: "test1@example.com"})
      user2 = user_fixture(%{email: "test2@example.com"})

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
        assert {:ok, users} = Accounts.find_users(%{params: params, scope: scope})

        assert length(users) == 3
        user_ids = Enum.map(users, & &1.id) |> Enum.sort()
        expected_ids = [setup_user.id, user1.id, user2.id] |> Enum.sort()
        assert user_ids == expected_ids
      end
    end

    test "returns User structs with all expected fields", %{user: user, scope: scope} do
      assert {:ok, users} = Accounts.find_users(%{params: %{}, scope: scope})

      assert length(users) == 1
      user_result = hd(users)

      # Verify it's a proper User struct
      assert %User{} = user_result
      assert user_result.id == user.id
      assert user_result.email == user.email
      assert user_result.name == user.name
      assert user_result.confirmed_at == user.confirmed_at
      assert is_struct(user_result.inserted_at, DateTime)
      assert is_struct(user_result.updated_at, DateTime)
    end

    test "ignores scope and returns all users regardless of scope user", %{user: _setup_user} do
      # Create a different user for the scope
      different_user = user_fixture(%{email: "different@example.com"})
      different_scope = Scope.for_user(different_user)

      # Create additional users
      _user1 = user_fixture(%{email: "test1@example.com"})
      _user2 = user_fixture(%{email: "test2@example.com"})

      assert {:ok, users} = Accounts.find_users(%{params: %{}, scope: different_scope})

      # Should return all users, not just the scope user
      assert length(users) == 4
      user_emails = Enum.map(users, & &1.email) |> Enum.sort()

      # Since we don't know the exact email of setup_user, let's just verify count and presence
      assert length(user_emails) == 4
      assert "different@example.com" in user_emails
      assert "test1@example.com" in user_emails
      assert "test2@example.com" in user_emails
    end

    test "works with nil scope" do
      _user1 = user_fixture(%{email: "test1@example.com"})
      _user2 = user_fixture(%{email: "test2@example.com"})

      assert {:ok, users} = Accounts.find_users(%{params: %{}, scope: nil})

      assert length(users) >= 2
      user_emails = Enum.map(users, & &1.email)
      assert "test1@example.com" in user_emails
      assert "test2@example.com" in user_emails
    end

    test "handles mixed profile states correctly", %{user: setup_user, scope: scope} do
      user_with_profile = user_fixture(%{email: "with_profile@example.com"})
      user_without_profile = user_fixture(%{email: "without_profile@example.com"})

      # Create profile for one user only
      profile_attrs = %{bio: "I have a profile", user_id: user_with_profile.id}

      {:ok, _profile} =
        %Profile{}
        |> Profile.changeset(profile_attrs)
        |> Repo.insert()

      assert {:ok, users} = Accounts.find_users(%{params: %{}, scope: scope})

      assert length(users) == 3

      # Find users in result
      user_with_profile_result = Enum.find(users, &(&1.id == user_with_profile.id))
      user_without_profile_result = Enum.find(users, &(&1.id == user_without_profile.id))
      setup_user_result = Enum.find(users, &(&1.id == setup_user.id))

      # Verify all have profile association preloaded
      assert Ecto.assoc_loaded?(user_with_profile_result.profile)
      assert Ecto.assoc_loaded?(user_without_profile_result.profile)
      assert Ecto.assoc_loaded?(setup_user_result.profile)

      # Verify profile content
      assert user_with_profile_result.profile.bio == "I have a profile"
      assert user_without_profile_result.profile == nil
      assert setup_user_result.profile == nil
    end
  end

  describe "input validation" do
    setup do
      user = user_fixture()
      scope = Scope.for_user(user)

      %{user: user, scope: scope}
    end

    test "handles nil params", %{scope: scope} do
      assert {:ok, users} = Accounts.find_users(%{params: nil, scope: scope})
      assert is_list(users)
    end

    test "handles empty params", %{scope: scope} do
      assert {:ok, users} = Accounts.find_users(%{params: %{}, scope: scope})
      assert is_list(users)
    end

    test "handles nil scope" do
      assert {:ok, users} = Accounts.find_users(%{params: %{}, scope: nil})
      assert is_list(users)
    end
  end

  describe "integration scenarios" do
    test "works correctly with large number of users" do
      user = user_fixture()
      scope = Scope.for_user(user)

      # Create multiple users with various profile states
      users_with_profiles =
        for i <- 1..3 do
          user = user_fixture(%{email: "profile_user_#{i}@example.com"})

          profile_attrs = %{bio: "Bio for user #{i}", user_id: user.id}

          {:ok, _profile} =
            %Profile{}
            |> Profile.changeset(profile_attrs)
            |> Repo.insert()

          user
        end

      users_without_profiles =
        for i <- 1..2 do
          user_fixture(%{email: "no_profile_user_#{i}@example.com"})
        end

      all_created_users = users_with_profiles ++ users_without_profiles

      assert {:ok, result} = Accounts.find_users(%{params: %{}, scope: scope})

      # Should include the setup user plus all created users
      assert length(result) == 6

      # Verify all created users are present
      result_ids = Enum.map(result, & &1.id)

      for created_user <- all_created_users do
        assert created_user.id in result_ids
      end

      # Verify profile states
      for user_result <- result do
        original_user = Enum.find(all_created_users, &(&1.id == user_result.id))

        assert Ecto.assoc_loaded?(user_result.profile)

        cond do
          original_user in users_with_profiles ->
            assert user_result.profile != nil
            assert String.contains?(user_result.profile.bio, "Bio for user")

          original_user in users_without_profiles or original_user == nil ->
            assert user_result.profile == nil
        end
      end
    end

    test "maintains data consistency across multiple calls" do
      user = user_fixture()
      scope = Scope.for_user(user)

      _user1 = user_fixture(%{email: "test1@example.com"})
      _user2 = user_fixture(%{email: "test2@example.com"})

      # First call
      assert {:ok, result1} = Accounts.find_users(%{params: %{}, scope: scope})

      # Second call should return identical results
      assert {:ok, result2} = Accounts.find_users(%{params: %{}, scope: scope})

      assert length(result1) == length(result2)
      assert length(result1) == 3

      # Compare results
      result1_ids = Enum.map(result1, & &1.id) |> Enum.sort()
      result2_ids = Enum.map(result2, & &1.id) |> Enum.sort()

      assert result1_ids == result2_ids
    end
  end
end
