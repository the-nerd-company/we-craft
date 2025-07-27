defmodule WeCraftWeb.Projects.Components.ProjectChatListComponent do
  @moduledoc """
  A live component for displaying and managing the list of project chats.
  This component handles the sidebar navigation for project chats.
  """
  use WeCraftWeb, :live_component

  alias WeCraft.Projects.ProjectPermissions

  # Required assigns
  attr :id, :string, required: true
  attr :chats, :list, required: true
  attr :current_chat, :map, default: nil
  attr :project, :map, required: true
  attr :current_scope, :map, required: true

  # Optional assigns with defaults
  attr :class, :string, default: "w-80 border-r border-base-200 bg-base-50 flex flex-col"

  def render(assigns) do
    ~H"""
    <div class={@class}>
      <!-- Sidebar Header -->
      <div class="p-4 border-b border-base-200">
        <div class="flex items-center justify-between">
          <h2 class="text-lg font-semibold text-base-content">Project Chats</h2>
          <.link navigate={~p"/"} class="btn btn-ghost btn-sm btn-circle" title="Go to Home">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-5 w-5"
              viewBox="0 0 20 20"
              fill="currentColor"
            >
              <path
                fill-rule="evenodd"
                d="M9.707 14.707a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414l4-4a1 1 0 011.414 1.414L7.414 9H15a1 1 0 110 2H7.414l2.293 2.293a1 1 0 010 1.414z"
                clip-rule="evenodd"
              />
            </svg>
          </.link>
        </div>
        <p class="text-sm text-base-content/70 mt-1">{@project.title}</p>

        <%= if ProjectPermissions.can_update_project?(@project, @current_scope)  do %>
          <button
            phx-click="open-new-channel-modal"
            phx-target={@myself}
            class="btn btn-primary btn-sm w-full mt-3"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-4 w-4 mr-2"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M12 4v16m8-8H4"
              />
            </svg>
            New Channel
          </button>
        <% end %>
      </div>
      
    <!-- Chat List -->
      <div class="flex-1 overflow-y-auto">
        <%= if Enum.empty?(@chats) do %>
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
            <p class="text-sm">No chats available</p>
          </div>
        <% else %>
          <%= for chat <- @chats do %>
            <button
              phx-click="select-chat"
              phx-value-chat-id={chat.id}
              phx-target={@myself}
              class={
                "w-full text-left p-4 border-b border-base-200 hover:bg-base-100 transition-colors #{if @current_chat && chat.id == @current_chat.id, do: "bg-primary/10 border-l-4 border-l-primary"}"
              }
            >
              <div class="flex items-center gap-3">
                <div class="flex-1 min-w-0">
                  <p class="font-medium text-base-content truncate">
                    {get_chat_display_name(chat)}
                  </p>
                  <p class="text-sm text-base-content/70 truncate">
                    {get_chat_description(chat)}
                  </p>
                  <%= if is_list(chat.messages) and length(chat.messages) > 0 do %>
                    <% last_message = List.last(chat.messages) %>
                    <p class="text-xs text-base-content/50 truncate mt-1">
                      Last: {String.slice(last_message.content || "", 0, 30)}
                    </p>
                  <% end %>
                </div>
              </div>
            </button>
          <% end %>
        <% end %>
      </div>
    </div>
    """
  end

  def handle_event("select-chat", %{"chat-id" => chat_id}, socket) do
    # Send the event to the parent LiveView
    send(self(), {:chat_selected, String.to_integer(chat_id)})
    {:noreply, socket}
  end

  def handle_event("open-new-channel-modal", _params, socket) do
    send(self(), :open_new_channel_modal)
    {:noreply, socket}
  end

  defp get_chat_display_name(chat) do
    cond do
      chat.is_main -> "Main Chat"
      chat.name && chat.name != "" -> chat.name
      true -> "Chat ##{chat.id}"
    end
  end

  defp get_chat_description(chat) do
    cond do
      chat.is_main -> "General project discussion"
      chat.description && chat.description != "" -> chat.description
      true -> "Project chat"
    end
  end
end
