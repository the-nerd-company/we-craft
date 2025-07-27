defmodule WeCraft.Chats.UseCases.CreateDmChatUseCase do
  @moduledoc """
  Use case for sending direct messages (DM) between users.
  """
  alias WeCraft.Chats.Chat
  alias WeCraft.Chats.ChatPermissions

  alias WeCraft.Chats.Infrastructure.{
    ChatMemberRepositoryEcto,
    ChatRepositoryEcto
  }

  def create_dm_chat(%{attrs: attrs, scope: scope}) do
    with true <- ChatPermissions.can_send_message?(attrs, scope),
         chat <-
           ChatRepositoryEcto.get_dm_chat(%{
             sender_id: attrs.sender_id,
             recipient_id: attrs.recipient_id
           }) do
      maybe_create_dm_chat(%{attrs: attrs, chat: chat})
    end
  end

  defp maybe_create_dm_chat(%{chat: %Chat{} = chat}) do
    {:ok, chat}
  end

  defp maybe_create_dm_chat(%{
         attrs: %{sender_id: sender_id, recipient_id: recipient_id},
         chat: nil
       }) do
    {:ok, chat} =
      ChatRepositoryEcto.create_chat(%{
        type: "dm",
        is_public: false,
        is_main: false,
        room_uuid: Ecto.UUID.generate()
      })

    {:ok, _} =
      ChatMemberRepositoryEcto.create_chat_member(%{
        user_id: sender_id,
        chat_id: chat.id,
        joined_at: DateTime.utc_now()
      })

    {:ok, _m} =
      ChatMemberRepositoryEcto.create_chat_member(%{
        user_id: recipient_id,
        chat_id: chat.id,
        joined_at: DateTime.utc_now()
      })

    {:ok, chat}
  end
end
