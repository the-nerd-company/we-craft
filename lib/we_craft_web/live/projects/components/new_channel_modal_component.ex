defmodule WeCraftWeb.Projects.Components.NewChannelModalComponent do
  @moduledoc """
  A live component for creating a new project channel.
  """
  use WeCraftWeb, :live_component

  alias WeCraft.Chats

  # Required assigns
  attr :id, :string, required: true
  attr :project, :map, required: true
  attr :show, :boolean, default: false

  def render(assigns) do
    ~H"""
    <div class={
      "fixed inset-0 z-50 #{if @show, do: "flex", else: "hidden"} items-center justify-center bg-black bg-opacity-50"
    }>
      <div class="bg-base-100 rounded-lg shadow-xl w-full max-w-md mx-4">
        <div class="p-6">
          <!-- Header -->
          <div class="flex items-center justify-between mb-4">
            <h3 class="text-lg font-semibold text-base-content">Create New Channel</h3>
            <button phx-click="close" phx-target={@myself} class="btn btn-ghost btn-sm btn-circle">
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
                  d="M6 18L18 6M6 6l12 12"
                />
              </svg>
            </button>
          </div>
          
    <!-- Form -->
          <.form
            :let={f}
            for={%{}}
            as={:channel}
            phx-submit="create-channel"
            phx-target={@myself}
            class="space-y-4"
          >
            <div>
              <label class="label">
                <span class="label-text">Channel Name</span>
              </label>
              <.input
                field={f[:name]}
                type="text"
                placeholder="e.g., general, random, dev-chat"
                required
                class="input input-bordered w-full"
              />
            </div>

            <div>
              <label class="label">
                <span class="label-text">Description (optional)</span>
              </label>
              <.input
                field={f[:description]}
                type="textarea"
                placeholder="What is this channel about?"
                rows="3"
                class="textarea textarea-bordered w-full"
              />
            </div>

            <div class="form-control">
              <label class="label cursor-pointer">
                <span class="label-text">Public Channel</span>
                <.input field={f[:is_public]} type="checkbox" checked={true} class="checkbox" />
              </label>
              <div class="text-xs text-base-content/70 mt-1">
                Public channels can be joined by all project members
              </div>
            </div>
            
    <!-- Actions -->
            <div class="flex justify-end gap-2 pt-4">
              <button type="button" phx-click="close" phx-target={@myself} class="btn btn-ghost">
                Cancel
              </button>
              <button type="submit" class="btn btn-primary">
                Create Channel
              </button>
            </div>
          </.form>
        </div>
      </div>
    </div>
    """
  end

  def handle_event("close", _params, socket) do
    send(self(), :close_new_channel_modal)
    {:noreply, socket}
  end

  def handle_event("create-channel", %{"channel" => channel_params}, socket) do
    attrs = %{
      name: channel_params["name"],
      description: channel_params["description"],
      is_public: channel_params["is_public"] == "true",
      is_main: false,
      type: "channel",
      project_id: socket.assigns.project.id
    }

    case Chats.create_project_chat(%{attrs: attrs}) do
      {:ok, chat} ->
        send(self(), {:channel_created, chat})
        send(self(), :close_new_channel_modal)
        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to create channel. Please try again.")}
    end
  end
end
