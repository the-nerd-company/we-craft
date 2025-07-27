defmodule WeCraftWeb.Profiles.Profiles do
  @moduledoc """
  LiveView for displaying user profiles.
  """
  use WeCraftWeb, :live_view

  alias WeCraft.Accounts
  alias WeCraftWeb.Components.Avatar

  def mount(_params, _session, socket) do
    {:ok, users} = Accounts.find_users(%{params: %{}, scope: socket.assigns.current_scope})
    {:ok, socket |> assign(:users, users)}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-base-100 to-base-200 p-6">
      <div class="mx-auto">
        <h1 class="text-3xl font-bold mb-6">User Profiles</h1>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <%= for user <- @users do %>
            <.link navigate={~p"/profile/#{user.id}"} class="block">
              <div class="bg-base-100 p-6 rounded-lg shadow-sm">
                <div class="flex items center gap-4">
                  <Avatar.avatar_small name={user.name || user.email} />
                  <div>
                    <h2 class="text-xl font-semibold">{user.name || "Anonymous User"}</h2>
                    <%= if user.name do %>
                      <p class="text-base-content/70">User Profile</p>
                    <% else %>
                      <p class="text-base-content/70">No name provided</p>
                    <% end %>
                  </div>
                </div>
              </div>
            </.link>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
