defmodule WeCraftWeb.Projects.Tickets.TicketFormComponent do
  @moduledoc """
  LiveComponent for creating and editing tickets.
  """
  use WeCraftWeb, :live_component

  alias WeCraft.Tickets.Ticket

  def update(assigns, socket) do
    changeset = assigns[:changeset] || Ticket.changeset(assigns.ticket, %{})

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)
     |> assign(:form, to_form(changeset))}
  end

  def handle_event("validate", %{"ticket" => params}, socket) do
    changeset =
      Ticket.changeset(socket.assigns.ticket, params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset), changeset: changeset)}
  end

  def handle_event("save", %{"ticket" => params}, socket) do
    send(self(), {__MODULE__, {:save, params}})
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      <.form
        for={@form}
        id={@id || "ticket-form"}
        phx-submit={@submit_event}
        phx-change="validate"
        class="space-y-6 max-w-xl"
        phx-target={@myself}
      >
        <div>
          <label class="block font-medium">Title</label>
          <.input field={@form[:title]} class="input input-bordered w-full" />
        </div>
        <div>
          <label class="block font-medium">Description</label>
          <.input field={@form[:description]} type="textarea" class="input input-bordered w-full" />
        </div>
        <div>
          <label class="block font-medium">Type</label>
          <.input
            field={@form[:type]}
            type="select"
            options={for t <- Ticket.get_customer_ticket_types(), do: {to_string(t), t}}
            class="input input-bordered w-full"
          />
        </div>
        <div>
          <label class="block font-medium">Status</label>
          <.input
            field={@form[:status]}
            type="select"
            options={for s <- Ticket.get_ticket_status(), do: {to_string(s), s}}
            class="input input-bordered w-full"
          />
        </div>
        <div>
          <label class="block font-medium">Priority</label>
          <.input field={@form[:priority]} type="number" class="input input-bordered w-full" />
        </div>
        <div class="flex gap-4">
          <button type="submit" class="btn btn-primary">Save</button>
          <.link patch={@cancel_path} class="btn">Cancel</.link>
        </div>
      </.form>
    </div>
    """
  end
end
