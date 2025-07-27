defmodule WeCraft.Accounts.UserCases.FindUsersUseCase do
  @moduledoc """
  Use case for finding users in the system.
  This use case interacts with the UserRepository to retrieve user data.
  """
  alias WeCraft.Accounts.Infrastructure.Ecto.UserRepositoryEcto

  def find_users(%{params: params, scope: _scope}) do
    {:ok, UserRepositoryEcto.search_users(params)}
  end
end
