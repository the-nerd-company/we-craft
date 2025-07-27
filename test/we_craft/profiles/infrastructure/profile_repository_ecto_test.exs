defmodule WeCraft.Profiles.Infrastructure.ProfileRepositoryEctoTest do
  @moduledoc """
  Tests for the ProfileRepositoryEcto module.
  """
  use WeCraft.DataCase, async: true

  alias WeCraft.Profiles.Infrastructure.ProfileRepositoryEcto
  alias WeCraft.Profiles.Profile

  import WeCraft.AccountsFixtures

  describe "create_profile/1" do
    test "creates a profile with valid attributes" do
      user = user_fixture()

      valid_attrs = %{
        bio: "Software engineer passionate about Phoenix LiveView",
        user_id: user.id
      }

      assert {:ok, %Profile{} = profile} = ProfileRepositoryEcto.create_profile(valid_attrs)
      assert profile.bio == "Software engineer passionate about Phoenix LiveView"
      assert profile.user_id == user.id
      assert profile.id
    end

    test "returns error changeset with invalid attributes" do
      user = user_fixture()

      # Missing required bio field
      invalid_attrs = %{user_id: user.id}

      assert {:error, %Ecto.Changeset{} = changeset} =
               ProfileRepositoryEcto.create_profile(invalid_attrs)

      assert %{bio: ["can't be blank"]} = errors_on(changeset)
    end

    test "returns error changeset with missing user_id" do
      # Missing user_id
      invalid_attrs = %{bio: "Some bio"}

      assert {:error, %Ecto.Changeset{} = changeset} =
               ProfileRepositoryEcto.create_profile(invalid_attrs)

      assert %{user_id: ["can't be blank"]} = errors_on(changeset)
    end

    test "returns error changeset with non-existent user_id" do
      # Non-existent user_id
      invalid_attrs = %{bio: "Some bio", user_id: 999_999}

      assert {:error, %Ecto.Changeset{} = changeset} =
               ProfileRepositoryEcto.create_profile(invalid_attrs)

      assert %{user_id: ["does not exist"]} = errors_on(changeset)
    end

    test "enforces unique user_id constraint" do
      user = user_fixture()
      valid_attrs = %{bio: "First profile", user_id: user.id}

      # Create first profile
      assert {:ok, _profile} = ProfileRepositoryEcto.create_profile(valid_attrs)

      # Try to create second profile for same user
      duplicate_attrs = %{bio: "Second profile", user_id: user.id}

      assert {:error, %Ecto.Changeset{} = changeset} =
               ProfileRepositoryEcto.create_profile(duplicate_attrs)

      assert %{user_id: ["has already been taken"]} = errors_on(changeset)
    end
  end

  describe "update_profile/2" do
    setup do
      user = user_fixture()

      {:ok, profile} =
        ProfileRepositoryEcto.create_profile(%{bio: "Original bio", user_id: user.id})

      %{user: user, profile: profile}
    end

    test "updates profile with valid attributes", %{profile: profile} do
      update_attrs = %{bio: "Updated bio content"}

      assert {:ok, %Profile{} = updated_profile} =
               ProfileRepositoryEcto.update_profile(profile, update_attrs)

      assert updated_profile.bio == "Updated bio content"
      assert updated_profile.id == profile.id
      assert updated_profile.user_id == profile.user_id
    end

    test "returns error changeset with invalid attributes", %{profile: profile} do
      invalid_attrs = %{bio: nil}

      assert {:error, %Ecto.Changeset{} = changeset} =
               ProfileRepositoryEcto.update_profile(profile, invalid_attrs)

      assert %{bio: ["can't be blank"]} = errors_on(changeset)
    end

    test "does not change profile with empty attributes", %{profile: profile} do
      assert {:ok, %Profile{} = updated_profile} =
               ProfileRepositoryEcto.update_profile(profile, %{})

      assert updated_profile.bio == profile.bio
      assert updated_profile.id == profile.id
    end

    test "cannot update user_id", %{profile: profile} do
      other_user = user_fixture()
      update_attrs = %{user_id: other_user.id}

      # user_id should not be updatable based on the update_changeset
      assert {:ok, %Profile{} = updated_profile} =
               ProfileRepositoryEcto.update_profile(profile, update_attrs)

      # Should remain unchanged
      assert updated_profile.user_id == profile.user_id
    end
  end

  describe "get_profile_by_user_id/1" do
    test "returns profile when user has a profile" do
      user = user_fixture()
      {:ok, profile} = ProfileRepositoryEcto.create_profile(%{bio: "Test bio", user_id: user.id})

      result = ProfileRepositoryEcto.get_profile_by_user_id(user.id)

      assert %Profile{} = result
      assert result.id == profile.id
      assert result.bio == "Test bio"
      assert result.user_id == user.id
      # Should be preloaded
      assert result.user
      assert result.user.id == user.id
    end

    test "returns nil when user has no profile" do
      user = user_fixture()

      result = ProfileRepositoryEcto.get_profile_by_user_id(user.id)

      assert result == nil
    end

    test "returns nil when user_id does not exist" do
      result = ProfileRepositoryEcto.get_profile_by_user_id(999_999)

      assert result == nil
    end

    test "preloads user association" do
      user = user_fixture()
      {:ok, _profile} = ProfileRepositoryEcto.create_profile(%{bio: "Test bio", user_id: user.id})

      result = ProfileRepositoryEcto.get_profile_by_user_id(user.id)

      assert result.user
      assert result.user.id == user.id
      assert result.user.email == user.email
      # Verify it's actually preloaded, not lazy-loaded
      assert Ecto.assoc_loaded?(result.user)
    end
  end

  describe "integration tests" do
    test "full CRUD lifecycle" do
      user = user_fixture()

      # Create
      create_attrs = %{bio: "I'm a passionate developer", user_id: user.id}
      assert {:ok, %Profile{} = profile} = ProfileRepositoryEcto.create_profile(create_attrs)
      assert profile.bio == "I'm a passionate developer"

      # Read
      found_profile = ProfileRepositoryEcto.get_profile_by_user_id(user.id)
      assert found_profile.id == profile.id

      # Update
      update_attrs = %{bio: "I'm a senior developer with 10 years of experience"}

      assert {:ok, %Profile{} = updated_profile} =
               ProfileRepositoryEcto.update_profile(profile, update_attrs)

      assert updated_profile.bio == "I'm a senior developer with 10 years of experience"

      # Verify update persisted
      updated_found = ProfileRepositoryEcto.get_profile_by_user_id(user.id)
      assert updated_found.bio == "I'm a senior developer with 10 years of experience"
    end

    test "handles multiple users with profiles" do
      user1 = user_fixture()
      user2 = user_fixture()

      # Create profiles for both users
      {:ok, profile1} =
        ProfileRepositoryEcto.create_profile(%{bio: "User 1 bio", user_id: user1.id})

      {:ok, profile2} =
        ProfileRepositoryEcto.create_profile(%{bio: "User 2 bio", user_id: user2.id})

      # Verify each user gets their own profile
      found_profile1 = ProfileRepositoryEcto.get_profile_by_user_id(user1.id)
      found_profile2 = ProfileRepositoryEcto.get_profile_by_user_id(user2.id)

      assert found_profile1.id == profile1.id
      assert found_profile1.bio == "User 1 bio"
      assert found_profile1.user.id == user1.id

      assert found_profile2.id == profile2.id
      assert found_profile2.bio == "User 2 bio"
      assert found_profile2.user.id == user2.id
    end
  end
end
