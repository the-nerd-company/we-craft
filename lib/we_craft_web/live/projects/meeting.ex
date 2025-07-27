defmodule WeCraftWeb.Projects.Meeting do
  @moduledoc """
  Live component for displaying meeting details.
  """
  use WeCraftWeb, :live_view

  alias WeCraft.Chats.Infrastructure.ChatRepositoryEcto

  def mount(%{"project_id" => project_id, "channel_id" => channel_id}, _session, socket) do
    chat = ChatRepositoryEcto.get_chat!(channel_id)
    {:ok, assign(socket, chat: chat, project_id: project_id)}
  end

  def render(assigns) do
    ~H"""
    <div
      id="room"
      class="h-screen	w-screen"
      phx-hook="CreateRoomHook"
      data-redirect-url={~p"/project/#{@project_id}"}
      data-room-name={@chat.room_uuid}
      data-user-name={@current_scope.user.name}
      data-user-email={@current_scope.user.email}
    >
    </div>
    """
  end
end
