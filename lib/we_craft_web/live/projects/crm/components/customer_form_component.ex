defmodule WeCraftWeb.Projects.CRM.CustomerFormComponent do
  @moduledoc """
  LiveComponent for customer form (create & edit).
  """
  use WeCraftWeb, :live_component

  alias WeCraft.CRM.Customer

  def update(assigns, socket) do
    changeset = assigns[:changeset] || Customer.changeset(assigns.customer, %{})

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)
     |> assign(:form, to_form(changeset))}
  end

  def handle_event("validate", %{"customer" => params}, socket) do
    changeset =
      Customer.changeset(socket.assigns.customer, params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset), changeset: changeset)}
  end

  def handle_event("save", %{"customer" => params}, socket) do
    send(self(), {__MODULE__, {:save, params}})
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      <.form
        for={@form}
        id={@id || "customer-form"}
        phx-submit={@submit_event}
        phx-change="validate"
        class="space-y-6 max-w-xl"
        phx-target={@myself}
      >
        <div>
          <label class="block font-medium">Name</label>
          <.input field={@form[:name]} class="input input-bordered w-full" />
        </div>
        <div>
          <label class="block font-medium">Email</label>
          <.input field={@form[:email]} class="input input-bordered w-full" />
        </div>
        <div>
          <label class="block font-medium">External ID</label>
          <.input field={@form[:external_id]} class="input input-bordered w-full" />
        </div>
        <div>
          <label class="block font-medium">Tags (comma separated)</label>
          <.input field={@form[:tags]} class="input input-bordered w-full" />
        </div>
        <div>
          <label class="block font-medium">Comment</label>
          <.input field={@form[:comment]} class="input input-bordered w-full" />
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
