defmodule WeCraft.Chats.Infrastructure.ChatMemberRepositoryEcto do
  @moduledoc """
  Ecto implementation of the ChatMemberRepository.
  """
  alias WeCraft.Chats.ChatMember
  alias WeCraft.Repo

  def create_chat_member(attrs) do
    %ChatMember{}
    |> ChatMember.changeset(attrs)
    |> Repo.insert()
  end
end
