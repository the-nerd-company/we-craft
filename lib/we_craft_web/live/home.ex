defmodule WeCraftWeb.Home do
  @moduledoc """
  LiveView for the home page of the We Craft application.
  """

  use WeCraftWeb, :live_view

  alias WeCraft.Projects
  alias WeCraftWeb.Components.ProjectCard
  alias WeCraftWeb.Projects.Components.SearchFormComponent

  def mount(_params, _session, socket) do
    {:ok, projects} = Projects.list_projects(%{})
    {:ok, assign(socket, :projects, projects)}
  end

  def handle_info({:search_projects, search_params}, socket) do
    # Use the search function we created earlier
    {:ok, search_results} = Projects.search_projects(search_params)

    {:noreply, assign(socket, :projects, search_results)}
  end

  def render(assigns) do
    ~H"""
    <div class="home-page min-h-screen bg-gradient-to-br from-base-100 to-base-200">
      <div class="container mx-auto px-4 py-8">
        <div class="text-center mb-8">
          <h1 class="text-4xl font-bold mb-4 bg-gradient-to-r from-primary to-accent bg-clip-text text-transparent">
            Welcome to We Craft
          </h1>
          <p class="text-lg text-base-content/80">
            Explore projects and connect with developers.
          </p>
        </div>

        <.live_component module={SearchFormComponent} id="project-search" selected_tags={[]} />

        <div class="flex justify-between items-center mb-6">
          <h2 class="text-2xl font-semibold">{length(@projects)} Projects Found</h2>
        </div>

        <%= if @projects == [] do %>
          <div class="text-center py-12">
            <p class="text-base-content/70 text-lg">No projects match your search criteria.</p>
            <p class="text-base-content/60 mt-2">
              Try adjusting your filters or browse all projects.
            </p>
          </div>
        <% else %>
          <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 2xl:grid-cols-5 gap-6">
            <%= for project <- @projects do %>
              <.link navigate={~p"/project/#{project.id}"} class="block">
                <ProjectCard.liquid_glass_card project={project} />
              </.link>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
