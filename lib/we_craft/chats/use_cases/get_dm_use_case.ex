defmodule WeCraft.Chats.UseCases.GetDmUseCase do
  @moduledoc """
  Use case for retrieving a direct message (DM) chat.
  """
  alias WeCraft.Chats.Infrastructure.ChatRepositoryEcto

  def get_dm_chat(%{chat_id: id, scope: _scope}) do
    {:ok, ChatRepositoryEcto.get_chat!(id)}
  end
end
