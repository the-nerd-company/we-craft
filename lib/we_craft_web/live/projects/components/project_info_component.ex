defmodule WeCraftWeb.Projects.Components.ProjectInfoComponent do
  @moduledoc """
  A live component for displaying project information in the right sidebar.
  This component shows project details, owner info, timeline, and action buttons.
  """
  use WeCraftWeb, :live_component

  alias WeCraft.Projects.ProjectPermissions
  alias WeCraftWeb.Components.Avatar

  # Required assigns
  attr :id, :string, required: true
  attr :project, :map, required: true
  attr :events, :list, required: true
  attr :current_scope, :map, default: nil
  attr :following, :boolean, required: true
  attr :followers_count, :integer, required: true

  # Optional assigns with defaults
  attr :class, :string,
    default: "w-full lg:w-96 border-l border-base-200 bg-base-50 overflow-y-auto"

  def render(assigns) do
    ~H"""
    <div class={@class}>
      <div class="p-6">
        <div class="bg-base-100 rounded-lg p-6 shadow-sm mb-6">
          <h1 class="text-3xl font-bold mb-2 bg-gradient-to-r from-primary to-accent bg-clip-text text-transparent">
            {@project.title}
          </h1>
          <div class="flex gap-2 mt-2 mb-4">
            <span class="badge badge-primary">
              {String.capitalize(to_string(@project.status))}
            </span>
            <span class="badge badge-accent">
              {String.capitalize(to_string(@project.visibility))}
            </span>
            <%= if ProjectPermissions.can_update_project?(@project, @current_scope) do %>
              <.link navigate={~p"/project/#{@project.id}/edit"} class="btn btn-sm">
                Edit
              </.link>
            <% end %>
          </div>
          <div class="mb-4">
            <h2 class="text-lg font-semibold mb-2">Description</h2>
            <p class="text-base-content/90 leading-relaxed">{@project.description}</p>
          </div>
          <div class="mb-4">
            <h2 class="text-lg font-semibold mb-2">Tech Stack</h2>
            <div class="flex flex-wrap gap-2">
              <%= for tag <- @project.tags do %>
                <div class="badge badge-outline badge-secondary">{tag}</div>
              <% end %>
              <%= if Enum.empty?(@project.tags) do %>
                <p class="text-base-content/70 italic">No tech stack specified yet</p>
              <% end %>
            </div>
          </div>
          <div class="mb-4">
            <h2 class="text-lg font-semibold mb-2">Project Needs</h2>
            <div class="flex flex-wrap gap-2">
              <%= for need <- @project.needs do %>
                <div class="badge badge-outline badge-accent">{need}</div>
              <% end %>
              <%= if Enum.empty?(@project.needs) do %>
                <p class="text-base-content/70 italic">No specific needs listed</p>
              <% end %>
            </div>
          </div>
          <div class="mb-4">
            <h2 class="text-lg font-semibold mb-2">Business Area</h2>
            <div class="flex flex-wrap gap-2">
              <%= for domain <- @project.business_domains do %>
                <div class="badge badge-outline badge-accent">{domain}</div>
              <% end %>
              <%= if Enum.empty?(@project.business_domains) do %>
                <p class="text-base-content/70 italic">No specific business areas listed</p>
              <% end %>
            </div>
          </div>
          <%= if @project.repository_url do %>
            <div class="mb-4">
              <h2 class="text-lg font-semibold mb-2">Repository</h2>
              <a
                href={@project.repository_url}
                target="_blank"
                rel="noopener noreferrer"
                class="flex items-center gap-2 text-primary hover:text-primary-focus transition-colors"
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-5 w-5"
                  viewBox="0 0 20 20"
                  fill="currentColor"
                >
                  <path
                    fill-rule="evenodd"
                    d="M12.316 3.051a1 1 0 01.633 1.265l-4 12a1 1 0 11-1.898-.632l4-12a1 1 0 011.265-.633zM5.707 6.293a1 1 0 010 1.414L3.414 10l2.293 2.293a1 1 0 11-1.414 1.414l-3-3a1 1 0 010-1.414l3-3a1 1 0 011.414 0zm8.586 0a1 1 0 011.414 0l3 3a1 1 0 010 1.414l-3 3a1 1 0 11-1.414-1.414L16.586 10l-2.293-2.293a1 1 0 010-1.414z"
                    clip-rule="evenodd"
                  />
                </svg>
                <span class="font-medium">View Repository</span>
              </a>
            </div>
          <% end %>
          <div class="mb-4">
            <h2 class="text-lg font-semibold mb-2">Project Owner</h2>
            <div class="flex items-center gap-2">
              <Avatar.avatar name={@project.owner.name} />
              <div>
                <h3 class="font-medium text-lg">{@project.owner.name}</h3>
              </div>
            </div>
          </div>
          <div class="mb-4">
            <div class="flex items-center justify-between">
              <h2 class="text-lg font-semibold">Community</h2>
              <div class="flex items-center gap-2 text-base-content/70">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-5 w-5"
                  viewBox="0 0 20 20"
                  fill="currentColor"
                >
                  <path d="M13 6a3 3 0 11-6 0 3 3 0 016 0zM18 8a2 2 0 11-4 0 2 2 0 014 0zM14 15a4 4 0 00-8 0v3h8v-3zM6 8a2 2 0 11-4 0 2 2 0 014 0zM16 18v-3a5.972 5.972 0 00-.75-2.906A3.005 3.005 0 0119 15v3h-3zM4.75 12.094A5.973 5.973 0 004 15v3H1v-3a3 3 0 013.75-2.906z" />
                </svg>
                <span class="font-medium">{@followers_count} followers</span>
              </div>
            </div>
          </div>
          <div class="mb-4">
            <h2 class="text-lg font-semibold mb-2">Project Timeline</h2>
            <ul class="timeline timeline-snap-icon timeline-compact timeline-vertical">
              <%= for {event, index} <- Enum.with_index(@events) do %>
                <li>
                  <%= if index > 0 do %>
                    <hr class="bg-primary" />
                  <% end %>
                  <div class="timeline-middle">
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      viewBox="0 0 20 20"
                      fill="currentColor"
                      class="h-5 w-5 text-primary"
                    >
                      <path
                        fill-rule="evenodd"
                        d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.857-9.809a.75.75 0 00-1.214-.882l-3.483 4.79-1.88-1.88a.75.75 0 10-1.06 1.061l2.5 2.5a.75.75 0 001.137-.089l4-5.5z"
                        clip-rule="evenodd"
                      />
                    </svg>
                  </div>
                  <div class="timeline-start md:text-end mb-2">
                    <time class="text-sm opacity-60">
                      {Calendar.strftime(event.inserted_at, "%B %d, %Y at %I:%M %p")}
                    </time>
                    <div class="text-base font-medium">{event.event_type}</div>
                  </div>
                  <%= if index < length(@events) - 1 do %>
                    <hr class="bg-primary" />
                  <% end %>
                </li>
              <% end %>
            </ul>
          </div>
          <div class="flex flex-wrap justify-center gap-2">
            <%= unless ProjectPermissions.can_update_project?(@project, @current_scope) or @current_scope == nil do %>
              <button class="btn btn-primary btn-sm" phx-click="open-contact-modal">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-5 w-5 mr-2"
                  viewBox="0 0 20 20"
                  fill="currentColor"
                >
                  <path d="M2.003 5.884L10 9.882l7.997-3.998A2 2 0 0016 4H4a2 2 0 00-1.997 1.884z" />
                  <path d="M18 8.118l-8 4-8-4V14a2 2 0 002 2h12a2 2 0 002-2V8.118z" />
                </svg>
                Contact Owner
              </button>
              <button
                class={"btn btn-secondary btn-sm #{if @following, do: "btn-active", else: ""}"}
                phx-click="toggle-follow"
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-5 w-5 mr-2"
                  viewBox="0 0 20 20"
                  fill="currentColor"
                >
                  <path d="M5 4a2 2 0 012-2h6a2 2 0 012 2v14l-5-2.5L5 18V4z" />
                </svg>
                {if @following, do: "Following", else: "Follow Project"}
              </button>
              <button class="btn btn-accent btn-sm" phx-click="join-team">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-5 w-5 mr-2"
                  viewBox="0 0 20 20"
                  fill="currentColor"
                >
                  <path d="M13 6a3 3 0 11-6 0 3 3 0 016 0zM18 8a2 2 0 11-4 0 2 2 0 014 0zM14 15a4 4 0 00-8 0v3h8v-3zM6 8a2 2 0 11-4 0 2 2 0 014 0zM16 18v-3a5.972 5.972 0 00-.75-2.906A3.005 3.005 0 0119 15v3h-3zM4.75 12.094A5.973 5.973 0 004 15v3H1v-3a3 3 0 013.75-2.906z" />
                </svg>
                Join Team
              </button>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def handle_event("open-dm", _params, socket) do
    # Send the event to the parent LiveView
    send(self(), :open_dm)
    {:noreply, socket}
  end

  def handle_event("open-contact-modal", _params, socket) do
    # Send the event to the parent LiveView
    send(self(), :open_contact_modal)
    {:noreply, socket}
  end

  def handle_event("toggle-follow", _params, socket) do
    # Send the event to the parent LiveView
    send(self(), :toggle_follow)
    {:noreply, socket}
  end

  def handle_event("join-team", _params, socket) do
    # Send the event to the parent LiveView
    send(self(), :join_team)
    {:noreply, socket}
  end
end
