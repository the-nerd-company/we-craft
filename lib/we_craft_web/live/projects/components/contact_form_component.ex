defmodule WeCraftWeb.Projects.Components.ContactFormComponent do
  @moduledoc """
  Component for the project contact form modal.
  """
  use WeCraftWeb, :live_component

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:message, "")}
  end

  def handle_event("validate", %{"message" => message}, socket) do
    {:noreply, assign(socket, :message, message)}
  end

  def handle_event("submit", %{"message" => message}, socket) do
    # Send the message to the parent LiveView
    send(self(), {:contact_form_submitted, message})
    {:noreply, socket}
  end

  def handle_event("cancel", _params, socket) do
    send(self(), :close_contact_modal)
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="modal modal-open">
      <div class="modal-box bg-base-100 max-w-md shadow-lg">
        <h3 class="font-bold text-lg">
          Contact {if @owner.name, do: String.split(@owner.name) |> List.first(), else: "Owner"}
        </h3>
        <div class="py-4">
          <form phx-submit="submit" phx-change="validate" phx-target={@myself} class="space-y-4">
            <div class="form-control">
              <label class="label">
                <span class="label-text">Your Message</span>
              </label>
              <textarea
                name="message"
                class="textarea textarea-bordered h-24"
                placeholder="Write your message here..."
                value={@message}
              ></textarea>
            </div>
            <div class="modal-action">
              <button type="submit" class="btn btn-primary">Send Message</button>
              <button type="button" class="btn" phx-click="cancel" phx-target={@myself}>
                Cancel
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
    """
  end
end
