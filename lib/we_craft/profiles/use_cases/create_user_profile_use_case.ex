defmodule WeCraft.Profiles.UseCases.CreateUserProfileUseCase do
  @moduledoc """
  Use case for creating a user profile.
  """
  alias WeCraft.Profiles.Infrastructure.ProfileRepositoryEcto

  def create_user_profile(%{attrs: attrs}) do
    ProfileRepositoryEcto.create_profile(attrs)
  end
end
