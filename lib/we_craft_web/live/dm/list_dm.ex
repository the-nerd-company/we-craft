defmodule WeCraftWeb.ListDm do
  @moduledoc """
  LiveView for listing direct message (DM) chats.
  This LiveView subscribes to the chat broadcaster to receive updates
  when new DMs are created.
  """
  use WeCraftWeb, :live_view

  alias WeCraft.Chats

  def mount(_params, _session, socket) do
    {:ok, dms} =
      Chats.list_dm_chats(%{
        user_id: socket.assigns.current_scope.user.id,
        scope: socket.assigns.current_scope
      })

    case dms do
      [first_dm | _] ->
        # Redirect to the first DM
        {:ok, push_navigate(socket, to: ~p"/dms/#{first_dm.id}")}

      [] ->
        # No DMs available, show empty state
        {:ok, assign(socket, dms: [])}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="flex items-center justify-center min-h-screen">
      <div class="text-center">
        <h1 class="text-2xl font-bold text-gray-800 mb-4">No Direct Messages</h1>
        <p class="text-gray-600 mb-8">You don't have any direct message conversations yet.</p>
        <.link navigate={~p"/"} class="btn btn-primary">
          Go to Home
        </.link>
      </div>
    </div>
    """
  end

  def handle_info({Chats, [:dm_created, dm]}, socket) do
    case socket.assigns.dms do
      [] ->
        # This was the first DM, redirect to it
        {:noreply, push_navigate(socket, to: ~p"/dms/#{dm.id}")}

      _existing_dms ->
        # Already have DMs, this shouldn't happen since we redirect
        # but handle it gracefully
        {:noreply, socket}
    end
  end
end
