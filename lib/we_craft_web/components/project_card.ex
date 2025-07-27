defmodule WeCraftWeb.Components.ProjectCard do
  @moduledoc """
  Component for displaying a minimalist project card
  """
  use Phoenix.Component

  alias WeCraftWeb.Projects.Components.ProjectStatusBadge

  attr :project, :map, required: true

  def liquid_glass_card(assigns) do
    ~H"""
    <div class="project-card group bg-base-100 shadow-md rounded-lg border border-base-300 transition-all duration-300 hover:shadow-xl hover:scale-[1.02] h-full flex flex-col">
      <div class="p-4 flex-1 flex flex-col">
        <div class="flex-1">
          <h3 class="text-lg font-semibold mb-2 line-clamp-2 group-hover:text-primary transition-colors">
            {@project.title}
          </h3>
          <p class="text-base-content/70 text-sm mb-4 line-clamp-3 leading-relaxed">
            {@project.description}
          </p>
        </div>

        <div class="mt-auto">
          <div class="flex flex-wrap gap-1 mb-3">
            <ProjectStatusBadge.project_status_badge_xs project={@project} />

            <%= if Map.get(@project, :tags) && length(Map.get(@project, :tags, [])) > 0 do %>
              <%= for tag <- Enum.take(Map.get(@project, :tags, []), 3) do %>
                <span class="badge badge-xs badge-outline opacity-70">
                  {tag}
                </span>
              <% end %>
              <%= if length(Map.get(@project, :tags, [])) > 3 do %>
                <span class="badge badge-xs badge-ghost opacity-50">
                  +{length(Map.get(@project, :tags, [])) - 3}
                </span>
              <% end %>
            <% end %>
          </div>

          <div class="flex justify-between items-center">
            <div class="text-xs text-base-content/50">
              <%= if Map.get(@project, :business_domains) && length(Map.get(@project, :business_domains, [])) > 0 do %>
                {Enum.join(Enum.take(Map.get(@project, :business_domains, []), 2), ", ")}
                <%= if length(Map.get(@project, :business_domains, [])) > 2 do %>
                  <span class="opacity-70">
                    +{length(Map.get(@project, :business_domains, [])) - 2}
                  </span>
                <% end %>
              <% end %>
            </div>

            <div class="flex items-center gap-2">
              <div class="flex items-center gap-1 text-xs text-base-content/50">
                <svg class="w-3 h-3" fill="currentColor" viewBox="0 0 20 20">
                  <path d="M9 6a3 3 0 11-6 0 3 3 0 016 0zM17 6a3 3 0 11-6 0 3 3 0 016 0zM12.93 17c.046-.327.07-.66.07-1a6.97 6.97 0 00-1.5-4.33A5 5 0 0119 16v1h-6.07zM6 11a5 5 0 015 5v1H1v-1a5 5 0 015-5z" />
                </svg>
                <span>{Map.get(@project, :followers_count, 0)}</span>
              </div>

              <div class="btn btn-xs btn-primary opacity-0 group-hover:opacity-100 transition-opacity">
                View
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
