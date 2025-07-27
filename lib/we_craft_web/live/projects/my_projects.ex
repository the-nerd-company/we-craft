defmodule WeCraftWeb.Projects.MyProjects do
  @moduledoc """
  LiveView for displaying the user's projects.
  """
  use WeCraftWeb, :live_view

  alias WeCraft.Projects

  def mount(_params, _session, socket) do
    {:ok, projects} =
      Projects.list_user_projects(%{user_id: socket.assigns.current_scope.user.id})

    {:ok, assign(socket, projects: projects, page_title: "My Projects")}
  end

  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">
      <.header>
        My Projects
        <:subtitle>Manage and explore your craft projects</:subtitle>
        <:actions>
          <.button navigate={~p"/projects/new"} variant="primary">
            <.icon name="hero-plus" class="size-4 mr-2" /> New Project
          </.button>
        </:actions>
      </.header>

      <div :if={@projects == []} class="flex flex-col items-center justify-center py-16 text-center">
        <div class="mb-6 p-4 bg-base-200 rounded-full">
          <.icon name="hero-document-plus" class="size-12 text-primary" />
        </div>
        <h3 class="text-xl font-semibold mb-2">No projects yet</h3>
        <p class="text-base-content/70 mb-6 max-w-md">
          Create your first project to start tracking your crafting journey
        </p>
        <.button navigate={~p"/projects/new"} variant="primary">
          <.icon name="hero-plus" class="size-4 mr-2" /> Create Your First Project
        </.button>
      </div>

      <div :if={@projects != []} class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mt-6">
        <%= for project <- @projects do %>
          <div class="card bg-base-100 shadow-lg hover:shadow-xl transition-all duration-300">
            <div class="card-body">
              <div class="flex justify-between items-start">
                <h2 class="card-title font-bold text-lg line-clamp-2">
                  {project.title}
                </h2>
                <div class="dropdown dropdown-end">
                  <div tabindex="0" role="button" class="btn btn-ghost btn-sm btn-circle">
                    <.icon name="hero-ellipsis-vertical" class="size-5" />
                  </div>
                  <ul
                    tabindex="0"
                    class="dropdown-content z-[1] menu p-2 shadow bg-base-100 rounded-box w-52"
                  >
                    <li><a href={~p"/project/#{project.id}"}>View Project</a></li>
                    <li><a href={~p"/project/#{project.id}/edit"}>Edit Project</a></li>
                  </ul>
                </div>
              </div>

              <div class="text-sm text-base-content/70 mt-1 mb-3 line-clamp-3">
                {project.description || "No description provided"}
              </div>

              <div class="flex flex-wrap gap-1 mt-2 mb-4">
                <%= for tag <- (project.tags || []) |> Enum.take(3) do %>
                  <span class="badge badge-outline badge-sm">{tag}</span>
                <% end %>
                <span :if={length(project.tags || []) > 3} class="badge badge-outline badge-sm">
                  +{length(project.tags || []) - 3} more
                </span>
              </div>

              <div class="card-actions justify-end mt-auto">
                <.button navigate={~p"/project/#{project.id}"} class="btn-sm">
                  View Project
                </.button>
              </div>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
