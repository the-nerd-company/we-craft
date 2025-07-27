defmodule WeCraft.Chats.UseCases.AddReactionUseCase do
  @moduledoc """
  Use case for adding reactions to chat messages.
  """

  alias WeCraft.Chats.{ChatBroadcaster, Message}
  alias WeCraft.Repo

  def add_reaction(%{message_id: message_id, emoji: emoji, user_id: user_id}) do
    case Repo.get(Message, message_id) |> Repo.preload(:sender) do
      nil ->
        {:error, :message_not_found}

      message ->
        updated_reactions = add_user_to_reaction(message.reactions, emoji, user_id)

        case Repo.update(Message.changeset(message, %{reactions: updated_reactions})) do
          {:ok, updated_message} ->
            # Broadcast the message update
            _ = ChatBroadcaster.broadcast_message_updated(updated_message)
            {:ok, updated_message}

          {:error, changeset} ->
            {:error, changeset}
        end
    end
  end

  defp add_user_to_reaction(reactions, emoji, user_id) do
    case Enum.find_index(reactions, fn r -> r["emoji"] == emoji end) do
      nil ->
        # Add new reaction
        new_reaction = %{
          "emoji" => emoji,
          "users" => [user_id]
        }

        reactions ++ [new_reaction]

      index ->
        # Update existing reaction
        reaction = Enum.at(reactions, index)
        users = reaction["users"] || []

        if user_id in users do
          # User already reacted, don't add again
          reactions
        else
          # Add user to existing reaction
          updated_reaction = %{reaction | "users" => users ++ [user_id]}
          List.replace_at(reactions, index, updated_reaction)
        end
    end
  end
end
