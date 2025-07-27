defmodule WeCraft.Chats.UseCases.ListProjectChatsUseCase do
  @moduledoc """
  Use case for listing chats associated with a specific project.
  """
  alias WeCraft.Chats.Infrastructure.ChatRepositoryEcto
  alias WeCraft.Repo

  def list_project_chats(%{project_id: project_id}) do
    {:ok, ChatRepositoryEcto.list_chats_by_project(project_id) |> Repo.preload(:messages)}
  end
end
