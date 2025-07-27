defmodule WeCraft.Chats.Infrastructure.MessagesRepositoryEcto do
  @moduledoc """
  Ecto implementation of the MessagesRepository.
  """
  alias WeCraft.Chats.Message
  alias WeCraft.Repo

  def create_message(attrs) do
    %Message{}
    |> Message.changeset(attrs)
    |> Repo.insert()
  end
end
