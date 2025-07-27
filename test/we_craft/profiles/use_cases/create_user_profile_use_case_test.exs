defmodule WeCraft.Profiles.UseCases.CreateUserProfileUseCaseTest do
  @moduledoc """
  Tests for the CreateUserProfileUseCase module.
  """
  use WeCraft.DataCase

  alias WeCraft.Profiles
  alias WeCraft.Profiles.Profile

  import WeCraft.AccountsFixtures

  describe "execute/1" do
    test "creates a profile with valid attributes" do
      user = user_fixture()

      valid_attrs = %{
        bio: "Software engineer passionate about Phoenix LiveView",
        user_id: user.id
      }

      assert {:ok, %Profile{} = profile} = Profiles.create_user_profile(%{attrs: valid_attrs})
      assert profile.bio == "Software engineer passionate about Phoenix LiveView"
      assert profile.user_id == user.id
      assert profile.id
      assert profile.inserted_at
      assert profile.updated_at
    end

    test "returns error changeset with invalid attributes" do
      user = user_fixture()

      # Missing required bio field
      invalid_attrs = %{user_id: user.id}

      assert {:error, %Ecto.Changeset{} = changeset} =
               Profiles.create_user_profile(%{attrs: invalid_attrs})

      assert %{bio: ["can't be blank"]} = errors_on(changeset)
    end

    test "returns error changeset with missing user_id" do
      # Missing required user_id field
      invalid_attrs = %{bio: "Some bio"}

      assert {:error, %Ecto.Changeset{} = changeset} =
               Profiles.create_user_profile(%{attrs: invalid_attrs})

      assert %{user_id: ["can't be blank"]} = errors_on(changeset)
    end

    test "returns error changeset with non-existent user_id" do
      # Non-existent user_id
      invalid_attrs = %{bio: "Some bio", user_id: 999_999}

      assert {:error, %Ecto.Changeset{} = changeset} =
               Profiles.create_user_profile(%{attrs: invalid_attrs})

      assert %{user_id: ["does not exist"]} = errors_on(changeset)
    end

    test "enforces unique user_id constraint" do
      user = user_fixture()
      valid_attrs = %{bio: "First profile", user_id: user.id}

      # Create first profile
      assert {:ok, _profile} = Profiles.create_user_profile(%{attrs: valid_attrs})

      # Try to create second profile for same user
      duplicate_attrs = %{bio: "Second profile", user_id: user.id}

      assert {:error, %Ecto.Changeset{} = changeset} =
               Profiles.create_user_profile(%{attrs: duplicate_attrs})

      assert %{user_id: ["has already been taken"]} = errors_on(changeset)
    end

    test "creates profile with long bio content" do
      user = user_fixture()

      long_bio = """
      I am a passionate software engineer with over 10 years of experience in web development.
      I specialize in Elixir, Phoenix LiveView, and modern web technologies. I have worked on
      various projects ranging from small startups to enterprise applications. I enjoy building
      scalable and maintainable systems that solve real-world problems.
      """

      attrs = %{bio: long_bio, user_id: user.id}

      assert {:ok, %Profile{} = profile} = Profiles.create_user_profile(%{attrs: attrs})
      assert profile.bio == long_bio
      assert profile.user_id == user.id
    end

    test "creates profiles for different users" do
      user1 = user_fixture()
      user2 = user_fixture()

      attrs1 = %{bio: "User 1 profile", user_id: user1.id}
      attrs2 = %{bio: "User 2 profile", user_id: user2.id}

      assert {:ok, %Profile{} = profile1} = Profiles.create_user_profile(%{attrs: attrs1})
      assert {:ok, %Profile{} = profile2} = Profiles.create_user_profile(%{attrs: attrs2})

      assert profile1.bio == "User 1 profile"
      assert profile1.user_id == user1.id
      assert profile2.bio == "User 2 profile"
      assert profile2.user_id == user2.id
      assert profile1.id != profile2.id
    end

    test "handles empty bio gracefully" do
      user = user_fixture()
      attrs = %{bio: "", user_id: user.id}

      assert {:error, %Ecto.Changeset{} = changeset} =
               Profiles.create_user_profile(%{attrs: attrs})

      assert %{bio: ["can't be blank"]} = errors_on(changeset)
    end

    test "handles nil attrs gracefully" do
      assert_raise Ecto.CastError, fn ->
        Profiles.create_user_profile(%{attrs: nil})
      end
    end
  end
end
