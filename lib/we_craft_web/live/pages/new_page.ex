defmodule WeCraftWeb.Pages.NewPage do
  @moduledoc """
  LiveView for creating a new page in a project.
  """
  use WeCraftWeb, :live_view

  alias WeCraft.Pages
  alias WeCraft.Pages.Page
  alias WeCraft.Projects

  @impl true
  def mount(%{"project_id" => project_id}, _session, socket) do
    {:ok, project} =
      Projects.get_project(%{project_id: project_id, scope: socket.assigns.current_scope})

    changeset = Page.changeset(%Page{}, %{})

    {:ok,
     socket
     |> assign(:project, project)
     |> assign(:changeset, changeset)
     |> assign(:form, to_form(changeset))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.form
      for={@form}
      phx-change="validate"
      phx-submit="save"
      class="space-y-6"
      id="new-milestone-form"
    >
      <div class="form-control">
        <label class="label">
          <span class="label-text font-medium">
            Title <span class="text-error">*</span>
          </span>
        </label>
        <.input
          field={@form[:title]}
          type="text"
          placeholder="Enter Page title..."
          class="input input-bordered w-full"
          required
        />

        <div class="flex justify-end gap-4 pt-6 border-t border-base-200">
          <button type="button" phx-click="cancel" class="btn btn-ghost">
            Cancel
          </button>
          <button type="submit" class="btn btn-primary" disabled={!@form.source.valid?}>
            <.icon name="hero-flag" class="w-4 h-4 mr-2" /> Create Page
          </button>
        </div>
      </div>
    </.form>
    """
  end

  @impl true
  def handle_event("validate", %{"page" => page_params}, socket) do
    page_params = add_params(page_params, socket)

    changeset =
      %Page{}
      |> Page.changeset(page_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, changeset: changeset, form: to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"page" => page_params}, socket) do
    page_params = add_params(page_params, socket)

    case Pages.create_page(%{
           attrs: page_params,
           project: socket.assigns.project,
           scope: socket.assigns.current_scope
         }) do
      {:ok, page} ->
        {:noreply,
         socket
         |> put_flash(:info, "Page and block created successfully!")
         |> redirect(to: ~p"/project/#{page.project_id}/pages/#{page.id}")}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset, form: to_form(changeset))}
    end
  end

  defp add_params(attrs, socket) do
    Map.put(attrs, "project_id", socket.assigns.project.id)
    |> Map.put("slug", Slug.slugify(attrs["title"]))
  end
end
