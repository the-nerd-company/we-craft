defmodule WeCraft.Chats do
  @moduledoc """
  The Chat context for managing chat messages.
  """

  alias WeCraft.Chats.ChatBroadcaster

  alias WeCraft.Chats.UseCases.{
    AddReactionUseCase,
    CreateDmChatUseCase,
    CreateProjectChatUseCase,
    GetDmUseCase,
    ListDmUseCase,
    ListProjectChatsUseCase,
    SendMessageUseCase,
    ToggleReactionUseCase
  }

  @doc """
  Creates a new project chat.

  ## Examples

    iex> create_project_chat(%{})
    {:ok, %Message{}}
  """
  defdelegate create_project_chat(params), to: CreateProjectChatUseCase

  @doc """
  Lists all chats for a project.

  ## Examples

    iex> list_project_chats(%{})
    {:ok, %Message{}}
  """
  defdelegate list_project_chats(params), to: ListProjectChatsUseCase

  @doc """
  Sends a new message to a chat.

  ## Examples

      iex> send_message(%{chat_id: 123, sender_id: 456, content: "Hello"})
      {:ok, %Message{}}
  """
  defdelegate send_message(params), to: SendMessageUseCase

  @doc """
  Subscribes the current process to messages in the chat.

  ## Examples

    iex> send_message(123)
  """
  def subscribe_to_chat(chat_id), do: ChatBroadcaster.subscribe(chat_id)

  @doc """
  Unsubscribes the current process from messages in the chat.

  ## Examples

    iex> unsubscribe_from_chat(123)
  """
  def unsubscribe_from_chat(chat_id), do: ChatBroadcaster.unsubscribe(chat_id)

  @doc """
  Adds a reaction to a message.

  ## Examples

    iex> add_reaction_to_message(123, "👍", 456)
    {:ok, %Message{}}
  """
  def add_reaction_to_message(message_id, emoji, user_id) do
    AddReactionUseCase.add_reaction(%{
      message_id: message_id,
      emoji: emoji,
      user_id: user_id
    })
  end

  @doc """
  Toggles a reaction on a message (add if not present, remove if present).

  ## Examples

    iex> toggle_reaction(%{message_id: 123, emoji: "👍", user_id: 456})
    {:ok, %Message{}}
  """
  defdelegate toggle_reaction(params), to: ToggleReactionUseCase

  defdelegate list_dm_chats(attrs), to: ListDmUseCase

  defdelegate create_dm_chat(attrs), to: CreateDmChatUseCase

  defdelegate get_dm_chat(attrs), to: GetDmUseCase
end
