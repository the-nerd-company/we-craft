defmodule WeCraft.Chats.ChatPermissions do
  @moduledoc """
  Permissions module for handling chat access and message sending rules.
  """

  def can_send_message?(%{sender_id: sender_id}, %{user: %{id: user_id}})
      when sender_id == user_id, do: true

  def can_send_message?(%{sender_id: sender_id}, %{user: %{id: user_id}})
      when sender_id != user_id, do: {:error, :permission_denied}
end
