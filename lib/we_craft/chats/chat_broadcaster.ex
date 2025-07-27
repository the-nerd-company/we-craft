defmodule WeCraft.Chats.ChatBroadcaster do
  @moduledoc """
  Handles broadcasting chat messages using Phoenix.PubSub.
  """

  alias Phoenix.PubSub

  @pubsub WeCraft.PubSub

  @doc """
  Broadcasts a new message to all subscribers of the chat room.
  """
  def broadcast_message(chat_id, message) do
    PubSub.broadcast(
      @pubsub,
      "chat:#{chat_id}",
      {:new_message, message}
    )
  end

  @doc """
  Broadcasts an updated message to all subscribers of the chat room.
  """
  def broadcast_message_updated(message) do
    PubSub.broadcast(
      @pubsub,
      "chat:#{message.chat_id}",
      {:message_updated, message}
    )
  end

  @doc """
  Subscribes the current process to the chat room's messages.
  """
  def subscribe(chat_id) do
    PubSub.subscribe(@pubsub, "chat:#{chat_id}")
  end

  @doc """
  Unsubscribes the current process from the chat room's messages.
  """
  def unsubscribe(chat_id) do
    PubSub.unsubscribe(@pubsub, "chat:#{chat_id}")
  end
end
