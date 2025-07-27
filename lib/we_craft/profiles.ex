defmodule WeCraft.Profiles do
  @moduledoc """
  A module for managing user profiles in the WeCraft application.
  """

  alias WeCraft.Profiles.Infrastructure.ProfileRepositoryEcto

  defdelegate create_user_profile(attrs), to: WeCraft.Profiles.UseCases.CreateUserProfileUseCase

  defdelegate update_user_profile(attrs), to: WeCraft.Profiles.UseCases.UpdateUserProfileUseCase

  @doc """
  Gets a profile by user ID.
  """
  def get_profile_by_user_id(user_id) do
    ProfileRepositoryEcto.get_profile_by_user_id(user_id)
  end

  @doc """
  Gets or creates a profile for a user.
  """
  def get_or_create_profile_for_user(user) do
    case get_profile_by_user_id(user.id) do
      nil ->
        # Create a profile with placeholder bio
        create_user_profile(%{attrs: %{bio: "Tell us about yourself...", user_id: user.id}})

      profile ->
        {:ok, profile}
    end
  end
end
