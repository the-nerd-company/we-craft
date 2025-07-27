defmodule WeCraft.Profiles.UseCases.UpdateUserProfileUseCase do
  @moduledoc """
  Use case for updating a user profile.
  """
  alias WeCraft.Profiles.Infrastructure.ProfileRepositoryEcto
  alias WeCraft.Profiles.Profile

  def update_user_profile(%{project: %Profile{} = profile, attrs: attrs}) do
    ProfileRepositoryEcto.update_profile(profile, attrs)
  end
end
