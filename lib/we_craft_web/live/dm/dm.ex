defmodule WeCraftWeb.Dm do
  @moduledoc """
  LiveView for handling direct message (DM) chats.
  This LiveView allows users to send and receive messages in a DM chat.
  """
  use WeCraftWeb, :live_view

  alias WeCraft.Chats
  alias WeCraftWeb.Components.Avatar

  defp get_sender_name(message) do
    case message.sender do
      %Ecto.Association.NotLoaded{} -> "User"
      %{name: name} when is_binary(name) -> name
      _ -> "User"
    end
  end

  defp get_other_user(dm, current_user_id) do
    dm.members
    |> Enum.find(fn member -> member.user.id != current_user_id end)
    |> case do
      %{user: user} -> user
      _ -> nil
    end
  end

  defp get_dm_display_name(dm, current_user_id) do
    case get_other_user(dm, current_user_id) do
      %{name: name} when is_binary(name) and name != "" -> name
      %{email: email} -> email
      _ -> "Unknown User"
    end
  end

  def mount(%{"chat_id" => chat_id}, _session, socket) do
    # Normalize chat_id to integer so comparisons against dm.id (integer) work for highlighting
    chat_id_int =
      case Integer.parse(chat_id) do
        {int, _} -> int
        # fallback to original if not parseable
        :error -> chat_id
      end

    # Load all DM chats for the sidebar
    {:ok, all_dms} =
      Chats.list_dm_chats(%{
        user_id: socket.assigns.current_scope.user.id,
        scope: socket.assigns.current_scope
      })

    {:ok, chat} =
      Chats.get_dm_chat(%{
        chat_id: chat_id_int,
        scope: socket.assigns.current_scope
      })

    # Subscribe to real-time updates if connected
    _ = if connected?(socket), do: Chats.subscribe_to_chat(chat.id)

    recipient =
      chat.members
      |> Enum.find(fn member -> member.user.id != socket.assigns.current_scope.user.id end)

    sender =
      chat.members
      |> Enum.find(fn member -> member.user.id == socket.assigns.current_scope.user.id end)

    socket =
      socket
      |> assign(
        chat: chat,
        all_dms: all_dms,
        current_chat_id: chat_id_int,
        recipient: recipient,
        sender: sender,
        messages: chat.messages |> Enum.sort_by(& &1.timestamp),
        message_form: to_form(%{"content" => ""}),
        current_user_id: socket.assigns.current_scope.user.id
      )

    {:ok, socket}
  end

  def handle_event("send_message", %{"content" => content}, socket) when content != "" do
    chat = socket.assigns.chat
    current_user = socket.assigns.current_scope.user

    # Send message using the regular send_message function which broadcasts
    case Chats.send_message(%{
           content: content,
           sender_id: current_user.id,
           chat_id: chat.id
         }) do
      {:ok, _message} ->
        # Clear the form, message will be added via PubSub
        socket = assign(socket, :message_form, to_form(%{"content" => ""}))
        {:noreply, socket}

      {:error, _error} ->
        {:noreply, put_flash(socket, :error, "Could not send message")}
    end
  end

  def handle_event("send_message", _, socket) do
    # Ignore empty messages
    {:noreply, socket}
  end

  def handle_event("add_reaction", %{"message-id" => message_id, "emoji" => emoji}, socket) do
    case Chats.add_reaction_to_message(message_id, emoji, socket.assigns.current_scope.user.id) do
      {:ok, _message} ->
        # The updated message will be broadcast via PubSub
        {:noreply, socket}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Could not add reaction")}
    end
  end

  def handle_event("toggle_reaction", %{"message-id" => message_id, "emoji" => emoji}, socket) do
    case Chats.toggle_reaction(%{
           message_id: message_id,
           emoji: emoji,
           user_id: socket.assigns.current_scope.user.id
         }) do
      {:ok, _message} ->
        # The updated message will be broadcast via PubSub
        {:noreply, socket}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Could not toggle reaction")}
    end
  end

  # Handle real-time message updates via PubSub
  def handle_info({:new_message, message}, socket) do
    socket = update(socket, :messages, fn messages -> messages ++ [message] end)
    {:noreply, socket}
  end

  def handle_info({:message_updated, message}, socket) do
    socket = update(socket, :messages, &update_message_in_list(&1, message))
    {:noreply, socket}
  end

  # Handle when a new DM is created
  def handle_info({Chats, [:dm_created, dm]}, socket) do
    socket = update(socket, :all_dms, fn dms -> [dm | dms] end)
    {:noreply, socket}
  end

  defp update_message_in_list(messages, updated_message) do
    Enum.map(messages, fn message ->
      if message.id == updated_message.id, do: updated_message, else: message
    end)
  end

  def render(assigns) do
    ~H"""
    <div class="flex h-screen bg-base-100">
      <!-- Left Sidebar - DM List -->
      <div class="w-80 border-r border-base-200 bg-base-50 flex flex-col">
        <!-- Sidebar Header -->
        <div class="p-4 border-b border-base-200">
          <div class="flex items-center justify-between">
            <h2 class="text-lg font-semibold text-base-content">Direct Messages</h2>
            <.link navigate={~p"/"} class="btn btn-ghost btn-sm btn-circle" title="Go to Home">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-5 w-5"
                viewBox="0 0 20 20"
                fill="currentColor"
              >
                <path d="M10.707 2.293a1 1 0 00-1.414 0l-7 7a1 1 0 001.414 1.414L9 5.414V17a1 1 0 102 0V5.414l5.293 5.293a1 1 0 001.414-1.414l-7-7z" />
              </svg>
            </.link>
          </div>
        </div>
        
    <!-- DM List -->
        <div class="flex-1 overflow-y-auto">
          <%= if Enum.empty?(@all_dms) do %>
            <div class="p-4 text-center text-base-content/70">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-12 w-12 mx-auto mb-2 opacity-50"
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
              <p class="text-sm">No conversations yet</p>
            </div>
          <% else %>
            <%= for dm <- @all_dms do %>
              <.link
                navigate={~p"/dms/#{dm.id}"}
                class={
                  "block p-4 border-b border-base-200 hover:bg-base-100 transition-colors #{if dm.id == @current_chat_id, do: "bg-primary/10 border-l-4 border-l-primary"}"
                }
              >
                <div class="flex items-center gap-3">
                  <Avatar.avatar_small name={get_dm_display_name(dm, @current_user_id)} />

                  <div class="flex-1 min-w-0">
                    <p class="font-medium text-base-content truncate">
                      {get_dm_display_name(dm, @current_user_id)}
                    </p>
                    <%= if length(dm.messages) > 0 do %>
                      <% last_message = List.last(dm.messages) %>
                      <p class="text-sm text-base-content/70 truncate">
                        {String.slice(last_message.content || "", 0, 50)}
                      </p>
                    <% else %>
                      <p class="text-sm text-base-content/70 italic">No messages yet</p>
                    <% end %>
                  </div>
                </div>
              </.link>
            <% end %>
          <% end %>
        </div>
      </div>
      
    <!-- Main Chat Area -->
      <div class="flex-1 flex flex-col">
        <!-- Header -->
        <div class="flex items-center justify-between p-4 border-b border-base-200 bg-base-50">
          <div class="flex items-center gap-3">
            <Avatar.avatar_small name={@recipient.user.name || @recipient.user.email} />

            <div>
              <h1 class="text-lg font-semibold text-base-content">
                {@recipient.user.name || @recipient.user.email}
              </h1>
              <p class="text-sm text-base-content/70">Direct Message</p>
            </div>
          </div>
        </div>
        
    <!-- Messages Container -->
        <div
          id="messages-container"
          class="flex-1 overflow-y-auto p-4 space-y-4"
          phx-hook="chatScroll"
        >
          <%= if Enum.empty?(@messages) do %>
            <div class="flex items-center justify-center h-full">
              <div class="text-center text-base-content/70">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-16 w-16 mx-auto mb-4 opacity-50"
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
                <p class="text-lg font-medium">Start your conversation</p>
                <p class="text-sm">
                  Send a message to {@recipient.user.name || @recipient.user.email}
                </p>
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
                  "max-w-[80%] px-4 py-2 rounded-lg #{if message.sender_id == @current_user_id, do: "bg-primary text-primary-content rounded-br-sm", else: "bg-base-200 text-base-content rounded-bl-sm"}"
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
                    current_user={@current_scope.user}
                    chat_target={nil}
                  />
                <% else %>
                  <p class="text-sm">{message.content}</p>
                <% end %>
              </div>
            </div>
          <% end %>
        </div>
        
    <!-- Message Input -->
        <div class="p-4 border-t border-base-200 bg-base-50">
          <.form for={@message_form} phx-submit="send_message" class="flex gap-2 items-end">
            <div class="flex-1">
              <input
                type="text"
                name="content"
                class="input input-bordered w-full"
                placeholder={"Message #{@recipient.user.name || @recipient.user.email}..."}
                phx-hook="RichTextInput"
                id="dm-message-input"
                autocomplete="off"
              />
            </div>
            <button type="submit" class="btn btn-primary btn-square" title="Send message">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-5 w-5"
                viewBox="0 0 20 20"
                fill="currentColor"
              >
                <path d="M10.894 2.553a1 1 0 00-1.788 0l-7 14a1 1 0 001.169 1.409l5-1.429A1 1 0 009 15.571V11a1 1 0 112 0v4.571a1 1 0 00.725.962l5 1.428a1 1 0 001.17-1.408l-7-14z" />
              </svg>
            </button>
          </.form>
        </div>
      </div>
    </div>
    """
  end

  defp format_time(timestamp) do
    timestamp
    |> Calendar.strftime("%H:%M")
  end
end
