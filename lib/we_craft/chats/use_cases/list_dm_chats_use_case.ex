defmodule WeCraft.Chats.UseCases.ListDmUseCase do
  @moduledoc """
  Use case for listing direct messages (DMs) for a user.
  """
  alias WeCraft.Chats.Infrastructure.ChatRepositoryEcto

  def list_dm_chats(%{user_id: user_id, scope: _scope}) do
    chats =
      ChatRepositoryEcto.list_dm_chats(user_id)

    {:ok, chats}
  end
end
