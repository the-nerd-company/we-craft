defmodule WeCraft.Chats.UseCases.ToggleReactionUseCase do
  @moduledoc """
  Use case for toggling reactions on chat messages.
  """

  alias WeCraft.Chats.{ChatBroadcaster, Message}
  alias WeCraft.Repo

  def toggle_reaction(%{message_id: message_id, emoji: emoji, user_id: user_id}) do
    case Repo.get(Message, message_id) |> Repo.preload(:sender) do
      nil ->
        {:error, :message_not_found}

      message ->
        updated_reactions = toggle_user_reaction(message.reactions, emoji, user_id)

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

  defp toggle_user_reaction(reactions, emoji, user_id) do
    case Enum.find_index(reactions, fn r -> r["emoji"] == emoji end) do
      nil ->
        add_new_reaction(reactions, emoji, user_id)

      index ->
        update_existing_reaction(reactions, index, user_id)
    end
  end

  defp add_new_reaction(reactions, emoji, user_id) do
    new_reaction = %{
      "emoji" => emoji,
      "users" => [user_id]
    }

    reactions ++ [new_reaction]
  end

  defp update_existing_reaction(reactions, index, user_id) do
    reaction = Enum.at(reactions, index)
    users = reaction["users"] || []

    if user_id in users do
      remove_user_from_reaction(reactions, index, reaction, user_id)
    else
      add_user_to_reaction(reactions, index, reaction, user_id)
    end
  end

  defp remove_user_from_reaction(reactions, index, reaction, user_id) do
    updated_users = List.delete(reaction["users"], user_id)

    if updated_users == [] do
      List.delete_at(reactions, index)
    else
      updated_reaction = %{reaction | "users" => updated_users}
      List.replace_at(reactions, index, updated_reaction)
    end
  end

  defp add_user_to_reaction(reactions, index, reaction, user_id) do
    users = reaction["users"] || []
    updated_reaction = %{reaction | "users" => users ++ [user_id]}
    List.replace_at(reactions, index, updated_reaction)
  end
end
