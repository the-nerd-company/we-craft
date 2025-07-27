defmodule WeCraftWeb.Projects.ChatComponent do
  @moduledoc """
  Live component for chat functionality within a project.
  """
  use WeCraftWeb, :live_component

  alias WeCraft.Chats
  alias WeCraftWeb.Components.Avatar

  defp get_sender_name(message) do
    case message.sender do
      %Ecto.Association.NotLoaded{} -> "User"
      %{name: name} when is_binary(name) -> name
      _ -> "User"
    end
  end

  defp get_chat_display_name(chat) do
    cond do
      chat.is_main -> "Main Chat"
      chat.name && chat.name != "" -> chat.name
      true -> "Chat ##{chat.id}"
    end
  end

  def update(assigns, socket) do
    cond do
      # Initial mount
      socket.assigns[:id] != assigns.id ->
        initialize_component(assigns, socket)

      # New message from PubSub
      Map.has_key?(assigns, :new_message) ->
        add_new_message(assigns, socket)

      # Updated message from PubSub (e.g., reactions)
      Map.has_key?(assigns, :updated_message) ->
        update_existing_message(assigns, socket)

      # Chat changed - need to reinitialize with new chat
      socket.assigns[:chat] && assigns.chat && socket.assigns.chat.id != assigns.chat.id ->
        initialize_component(assigns, socket)

      # Regular update
      true ->
        {:ok, assign(socket, assigns)}
    end
  end

  defp initialize_component(%{chat: chat} = assigns, socket) do
    # Unsubscribe from previous chat if there was one
    if socket.assigns[:chat] && connected?(socket) do
      # Note: We don't have an unsubscribe function, but Phoenix will handle cleanup
      # when the process terminates or when we subscribe to a new topic
    end

    # Subscribe to new chat
    _ = if(connected?(socket), do: Chats.subscribe_to_chat(chat.id))

    current_user_id =
      if is_nil(assigns.current_user) do
        nil
      else
        assigns.current_user.id
      end

    socket =
      socket
      |> assign(assigns)
      |> assign(
        message_form: to_form(%{"content" => ""}),
        messages: chat.messages |> Enum.sort_by(& &1.timestamp),
        current_user_id: current_user_id
      )

    {:ok, socket}
  end

  defp add_new_message(%{new_message: new_message}, socket) do
    socket = update(socket, :messages, fn messages -> messages ++ [new_message] end)
    {:ok, socket}
  end

  defp update_existing_message(%{updated_message: updated_message}, socket) do
    socket =
      update(socket, :messages, fn messages ->
        update_message_in_list(messages, updated_message)
      end)

    {:ok, socket}
  end

  def handle_event("send_message", %{"content" => content}, socket) when content != "" do
    chat = socket.assigns.chat
    current_user = socket.assigns.current_user

    # Send message to the chat
    message_params = %{
      content: content,
      sender_id: current_user.id,
      chat_id: chat.id
    }

    case Chats.send_message(message_params) do
      {:ok, _message} ->
        # The message will be added via PubSub
        socket = assign(socket, :message_form, to_form(%{"content" => ""}))
        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not send message")}
    end
  end

  def handle_event("send_message", _, socket) do
    # Ignore empty messages
    {:noreply, socket}
  end

  def handle_event("add_reaction", %{"message-id" => message_id, "emoji" => emoji}, socket) do
    case socket.assigns.current_user do
      nil ->
        {:noreply, put_flash(socket, :error, "You must be logged in to add reactions")}

      current_user ->
        case Chats.add_reaction_to_message(message_id, emoji, current_user.id) do
          {:ok, _message} ->
            # The updated message will be broadcast via PubSub
            {:noreply, socket}

          {:error, _reason} ->
            {:noreply, put_flash(socket, :error, "Could not add reaction")}
        end
    end
  end

  def handle_event("toggle_reaction", %{"message-id" => message_id, "emoji" => emoji}, socket) do
    case socket.assigns.current_user do
      nil ->
        {:noreply, put_flash(socket, :error, "You must be logged in to toggle reactions")}

      current_user ->
        case Chats.toggle_reaction(%{
               message_id: message_id,
               emoji: emoji,
               user_id: current_user.id
             }) do
          {:ok, _message} ->
            # The updated message will be broadcast via PubSub
            {:noreply, socket}

          {:error, _reason} ->
            {:noreply, put_flash(socket, :error, "Could not toggle reaction")}
        end
    end
  end

  # Ensures component is properly updated when PubSub broadcasts happen
  def handle_info({:new_message, message}, socket) do
    socket = update(socket, :messages, fn messages -> messages ++ [message] end)
    {:noreply, socket}
  end

  defp update_message_in_list(messages, updated_message) do
    Enum.map(messages, fn message ->
      if message.id == updated_message.id do
        updated_message
      else
        message
      end
    end)
  end

  def render(assigns) do
    ~H"""
    <div class="bg-base-100 border border-base-200 rounded-lg shadow-sm h-full flex flex-col">
      <div class="p-4 border-b border-base-200 flex items-center justify-between">
        <div class="flex items-center gap-2">
          <h2 class="text-xl font-semibold">{get_chat_display_name(@chat)}</h2>
          <%= if @chat.is_main do %>
            <span class="badge badge-sm badge-primary">Main</span>
          <% end %>
          <.link
            navigate={~p"/project/#{@chat.project_id}/channels/#{@chat.id}/meeting"}
            class="btn btn-ghost btn-sm"
            title="Start video call"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-5 w-5"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 7h6a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2V9a2 2 0 012-2z"
              />
            </svg>
          </.link>
        </div>
      </div>

      <div
        id={"messages-container-#{@id}"}
        class="flex-1 overflow-y-auto p-4 space-y-4"
        phx-hook="chatScroll"
      >
        <%= if Enum.empty?(@messages) do %>
          <div class="flex items-center justify-center h-full">
            <div class="text-center text-base-content/70">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-12 w-12 mx-auto mb-4 opacity-50"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="1"
                  d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"
                />
              </svg>
              <p class="text-lg font-medium">No messages yet</p>
              <p class="text-sm">Start the conversation by sending a message below.</p>
            </div>
          </div>
        <% end %>

        <%= for message <- @messages do %>
          <div
            id={"message-#{message.id || System.unique_integer()}"}
            class={
              "flex gap-3 #{if message.sender_id == @current_user_id, do: "flex-row-reverse"}"
            }
          >
            <div class="flex-shrink-0">
              <Avatar.avatar_small name={get_sender_name(message)} />
            </div>
            <div class={
                "max-w-[80%] px-4 py-2 rounded-lg #{if message.sender_id == @current_user_id, do: "bg-primary text-primary-content", else: "bg-base-200 text-base-content"}"
              }>
              <div class="flex justify-between items-start mb-1">
                <span class="font-medium text-sm">
                  {get_sender_name(message)}
                </span>
                <span class="text-xs opacity-70 ml-2">
                  <%= if message.timestamp do %>
                    {format_time(message.timestamp)}
                  <% else %>
                    Just now
                  <% end %>
                </span>
              </div>

              <%= if WeCraft.Chats.Message.has_rich_content?(message) do %>
                <.live_component
                  module={WeCraftWeb.Components.RichMessage}
                  id={"rich-message-#{message.id || System.unique_integer()}"}
                  message={message}
                  current_user={@current_user}
                  chat_target={@myself}
                />
              <% else %>
                <p>{message.content}</p>
              <% end %>
            </div>
          </div>
        <% end %>
      </div>

      <div class="p-4 border-t border-base-200">
        <%= if @current_user != nil do %>
          <.form for={@message_form} phx-submit="send_message" phx-target={@myself} class="flex gap-2">
            <input
              type="text"
              name="content"
              class="input input-bordered flex-1"
              placeholder="Type your message... Use @username for mentions, :emoji: for emojis"
              phx-hook="RichTextInput"
              id={"rich-input-#{@id}"}
            />
            <button type="submit" class="btn btn-primary">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-5 w-5"
                viewBox="0 0 20 20"
                fill="currentColor"
              >
                <path d="M10.894 2.553a1 1 0 00-1.788 0l-7 14a1 1 0 001.169 1.409l5-1.429A1 1 0 009 15.571V11a1 1 0 112 0v4.571a1 1 0 00.725.962l5 1.428a1 1 0 001.17-1.408l-7-14z" />
              </svg>
              Send
            </button>
          </.form>
        <% else %>
          <p class="text-sm text-base-content/70">Please log in to send messages.</p>
        <% end %>
      </div>
    </div>
    """
  end

  defp format_time(timestamp) do
    timestamp
    |> Calendar.strftime("%H:%M")
  end
end
