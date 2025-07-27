defmodule WeCraft.Chats.UseCases.CreateProjectChatUseCase do
  @moduledoc """
  Use case for creating a chat for a new project.
  """
  alias WeCraft.Chats.Infrastructure.ChatRepositoryEcto

  def create_project_chat(%{attrs: attrs}) do
    ChatRepositoryEcto.create_chat(attrs)
  end
end
