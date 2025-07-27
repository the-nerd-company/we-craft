defmodule WeCraft.Chats.UseCases.SendMessageUseCase do
  @moduledoc """
  Use case for sending a message in a project chat.
  """
  alias WeCraft.Repo
  alias WeCraft.Chats.{ChatBroadcaster, Message}

  def send_message(attrs) do
    attrs = Map.put(attrs, :timestamp, DateTime.utc_now())

    %Message{}
    |> Message.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, message} ->
        message = Repo.preload(message, :sender)
        _ = ChatBroadcaster.broadcast_message(message.chat_id, message)
        {:ok, message}

      error ->
        error
    end
  end
end
