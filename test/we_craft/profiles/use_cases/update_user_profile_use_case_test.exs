defmodule WeCraft.Profiles.UseCases.UpdateUserProfileUseCaseTest do
  @moduledoc """
  Tests for the UpdateUserProfileUseCase module.
  """
  use WeCraft.DataCase

  alias WeCraft.Profiles.Infrastructure.ProfileRepositoryEcto
  alias WeCraft.Profiles.Profile
  alias WeCraft.Profiles.UseCases.{CreateUserProfileUseCase, UpdateUserProfileUseCase}

  import WeCraft.AccountsFixtures

  setup do
    user = user_fixture()

    {:ok, profile} =
      CreateUserProfileUseCase.create_user_profile(%{
        attrs: %{bio: "Original bio", user_id: user.id}
      })

    %{user: user, profile: profile}
  end

  describe "update_user_profile/1" do
    test "updates profile with valid attributes", %{profile: profile} do
      update_attrs = %{bio: "Updated bio content"}

      assert {:ok, %Profile{} = updated_profile} =
               UpdateUserProfileUseCase.update_user_profile(%{
                 project: profile,
                 attrs: update_attrs
               })

      assert updated_profile.bio == "Updated bio content"
      assert updated_profile.id == profile.id
      assert updated_profile.user_id == profile.user_id
      # updated_at should be greater than or equal to the original (may be same due to precision)
      assert NaiveDateTime.compare(updated_profile.updated_at, profile.updated_at) in [:gt, :eq]
    end

    test "returns error changeset with invalid attributes", %{profile: profile} do
      invalid_attrs = %{bio: nil}

      assert {:error, %Ecto.Changeset{} = changeset} =
               UpdateUserProfileUseCase.update_user_profile(%{
                 project: profile,
                 attrs: invalid_attrs
               })

      assert %{bio: ["can't be blank"]} = errors_on(changeset)
    end

    test "returns error changeset with empty bio", %{profile: profile} do
      invalid_attrs = %{bio: ""}

      assert {:error, %Ecto.Changeset{} = changeset} =
               UpdateUserProfileUseCase.update_user_profile(%{
                 project: profile,
                 attrs: invalid_attrs
               })

      assert %{bio: ["can't be blank"]} = errors_on(changeset)
    end

    test "does not change profile with empty attributes", %{profile: profile} do
      assert {:ok, %Profile{} = updated_profile} =
               UpdateUserProfileUseCase.update_user_profile(%{project: profile, attrs: %{}})

      assert updated_profile.bio == profile.bio
      assert updated_profile.id == profile.id
      assert updated_profile.user_id == profile.user_id
    end

    test "updates profile with long bio content", %{profile: profile} do
      long_bio = """
      I am a passionate software engineer with over 10 years of experience in web development.
      I specialize in Elixir, Phoenix LiveView, and modern web technologies. I have worked on
      various projects ranging from small startups to enterprise applications. I enjoy building
      scalable and maintainable systems that solve real-world problems.

      My expertise includes:
      - Backend development with Elixir and Phoenix
      - Frontend development with LiveView and modern JavaScript
      - Database design and optimization
      - DevOps and deployment strategies
      - Team leadership and mentoring
      """

      update_attrs = %{bio: long_bio}

      assert {:ok, %Profile{} = updated_profile} =
               UpdateUserProfileUseCase.update_user_profile(%{
                 project: profile,
                 attrs: update_attrs
               })

      assert updated_profile.bio == long_bio
      assert updated_profile.id == profile.id
    end

    test "cannot update user_id through attrs", %{profile: profile} do
      other_user = user_fixture()
      update_attrs = %{user_id: other_user.id}

      # user_id should not be updatable based on the update_changeset
      assert {:ok, %Profile{} = updated_profile} =
               UpdateUserProfileUseCase.update_user_profile(%{
                 project: profile,
                 attrs: update_attrs
               })

      # Should remain unchanged
      assert updated_profile.user_id == profile.user_id
    end

    test "preserves timestamps correctly", %{profile: profile} do
      original_inserted_at = profile.inserted_at
      update_attrs = %{bio: "New bio content"}

      assert {:ok, %Profile{} = updated_profile} =
               UpdateUserProfileUseCase.update_user_profile(%{
                 project: profile,
                 attrs: update_attrs
               })

      # inserted_at should remain the same
      assert updated_profile.inserted_at == original_inserted_at
      # updated_at should be greater than or equal to the original (may be same due to precision)
      assert NaiveDateTime.compare(updated_profile.updated_at, profile.updated_at) in [:gt, :eq]
    end

    test "handles multiple successive updates", %{profile: profile} do
      # First update
      first_attrs = %{bio: "First update"}

      assert {:ok, first_updated} =
               UpdateUserProfileUseCase.update_user_profile(%{
                 project: profile,
                 attrs: first_attrs
               })

      assert first_updated.bio == "First update"

      # Second update
      second_attrs = %{bio: "Second update"}

      assert {:ok, second_updated} =
               UpdateUserProfileUseCase.update_user_profile(%{
                 project: first_updated,
                 attrs: second_attrs
               })

      assert second_updated.bio == "Second update"
      assert second_updated.id == profile.id
      assert second_updated.user_id == profile.user_id
    end

    test "handles nil attrs gracefully", %{profile: profile} do
      assert_raise Ecto.CastError, fn ->
        UpdateUserProfileUseCase.update_user_profile(%{project: profile, attrs: nil})
      end
    end
  end

  describe "integration with repository" do
    test "updates are persisted to database", %{profile: profile} do
      update_attrs = %{bio: "Persisted bio update"}

      assert {:ok, updated_profile} =
               UpdateUserProfileUseCase.update_user_profile(%{
                 project: profile,
                 attrs: update_attrs
               })

      # Fetch from database to verify persistence
      from_db =
        ProfileRepositoryEcto.get_profile_by_user_id(profile.user_id)

      assert from_db.bio == "Persisted bio update"
      assert from_db.id == updated_profile.id
      assert from_db.updated_at == updated_profile.updated_at
    end
  end
end
