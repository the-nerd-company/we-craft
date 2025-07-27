defmodule WeCraft.Profiles.Infrastructure.ProfileRepositoryEcto do
  @moduledoc """
  Ecto implementation of the ProfileRepository.
  """

  alias WeCraft.Profiles.Profile
  alias WeCraft.Repo

  import Ecto.Query, warn: false

  def create_profile(attrs) do
    %Profile{}
    |> Profile.changeset(attrs)
    |> Repo.insert()
  end

  def update_profile(profile, attrs) do
    profile
    |> Profile.update_changeset(attrs)
    |> Repo.update()
  end

  def get_profile_by_user_id(user_id) do
    Repo.one(from p in Profile, where: p.user_id == ^user_id)
    |> Repo.preload(:user)
  end
end
