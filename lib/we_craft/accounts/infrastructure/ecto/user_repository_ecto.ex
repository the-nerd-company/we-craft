defmodule WeCraft.Accounts.Infrastructure.Ecto.UserRepositoryEcto do
  @moduledoc """
  Ecto-based implementation of the UserRepository.
  This module interacts with the database to manage user data.
  """

  alias WeCraft.Accounts.User
  alias WeCraft.Repo

  def search_users(_params) do
    User
    |> Repo.all()
    |> Repo.preload(:profile)
  end
end
