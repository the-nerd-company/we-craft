defmodule WeCraftWeb.Pages.Page do
  @moduledoc """
  LiveView for creating a new page in a project.
  """
  use WeCraftWeb, :live_view

  alias WeCraft.Pages.Page
  alias WeCraft.{Chats, Milestones, Pages, Projects}
  alias WeCraft.Pages.Infrastructure.Ecto.PageRepositoryEcto
  alias WeCraftWeb.Components.LeftMenu

  @impl true
  def mount(%{"project_id" => project_id, "page_id" => page_id}, _session, socket) do
    scope = socket.assigns.current_scope

    case Projects.get_project(%{project_id: project_id, scope: scope}) do
      {:ok, nil} ->
        {:ok, push_navigate(socket, to: ~p"/")}

      {:ok, project} ->
        changeset = Page.changeset(%Page{}, %{})

        # Get chats for the left menu
        {:ok, chats} = Chats.list_project_chats(%{project_id: project.id})
        {:ok, pages} = Pages.list_project_pages(%{project: project, scope: scope})

        # Load milestones for the project
        {:ok, milestones} =
          Milestones.list_project_milestones(%{project_id: project.id, scope: scope})

        # Get active milestones for the left menu
        active_milestones =
          milestones
          |> Enum.filter(&(&1.status == :active))

        current_page = PageRepositoryEcto.get_page(page_id)

        {:ok,
         socket
         |> assign(:project, project)
         |> assign(:chats, chats)
         |> assign(:current_chat, nil)
         |> assign(:current_section, :pages)
         |> assign(:current_page_id, String.to_integer(page_id))
         |> assign(:milestones, milestones)
         |> assign(:pages, pages)
         |> assign(:active_milestones, active_milestones)
         |> assign(:editing_task, nil)
         |> assign(:task_form, nil)
         |> assign(:page_title, current_page.title)
         |> assign(:current_page, current_page)
         |> assign(:changeset, changeset)
         |> assign(:editor_data, Jason.encode!(current_page.blocks))
         |> assign(:form, to_form(changeset))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="project-page min-h-screen bg-gradient-to-br from-base-100 to-base-200">
      <div class="flex h-screen">
        <!-- Left Menu -->
        <.live_component
          module={LeftMenu}
          id="left-menu"
          project={@project}
          pages={@pages}
          current_scope={@current_scope}
          current_section={@current_section}
          chats={@chats}
          current_page_id={@current_page_id}
          current_chat={@current_chat}
          active_milestones={@active_milestones}
        />
        <div class="flex-1 flex flex-col">
          <input
            type="text"
            name="title"
            value={@current_page.title}
            phx-blur="edit_title"
            phx-change="edit_title"
            class="block w-full text-center text-4xl font-extrabold bg-transparent border-none outline-none px-0 py-4 mb-2 tracking-tight focus:bg-base-100 focus:shadow focus:rounded transition-all duration-150"
            style="font-family: inherit; letter-spacing: -0.01em;"
            placeholder="Page title..."
            autocomplete="off"
            spellcheck="true"
          />
          <div
            id="editor"
            phx-hook="Editor"
            phx-update="ignore"
            data-page-id={@current_page.id}
            data-content={@editor_data}
            class="flex-1 w-full bg-white px-4 py-3 transition-all duration-150 min-h-[120px] overflow-y-auto shadow-sm  "
          >
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("edit_title", %{"value" => title}, socket) do
    {:ok, updated_page} =
      PageRepositoryEcto.update_page(socket.assigns.current_page, %{"title" => title})

    {:noreply, assign(socket, :current_page, updated_page)}
  end

  @impl true
  def handle_event(
        "editor-update",
        %{"blocks" => blocks, "time" => _time, "version" => _version},
        socket
      ) do
    {:ok, _} = PageRepositoryEcto.update_page(socket.assigns.current_page, %{"blocks" => blocks})
    {:noreply, socket}
  end
end
