defmodule WeCraftWeb.Projects.ProjectInfo do
  @moduledoc """
  LiveView for displaying detailed project information.
  """
  alias WeCraft.Projects.ProjectEvent
  use WeCraftWeb, :live_view

  alias WeCraft.{Chats, Milestones, Pages, Projects}
  alias WeCraft.Projects.ProjectPermissions
  alias WeCraftWeb.Components.{Avatar, LeftMenu}
  alias WeCraftWeb.Projects.Components.ProjectStatusBadge

  def mount(%{"project_id" => project_id}, _session, socket) do
    project_id = String.to_integer(project_id)
    scope = socket.assigns.current_scope

    case Projects.get_project(%{project_id: project_id, scope: scope}) do
      {:ok, nil} ->
        {:ok, push_navigate(socket, to: ~p"/")}

      {:ok, project} ->
        # Get chats for the left menu
        {:ok, chats} = Chats.list_project_chats(%{project_id: project.id})

        # Get project events for timeline
        {:ok, events} = Projects.list_project_events(%{project_id: project.id})

        {:ok, pages} = Pages.list_project_pages(%{project: project, scope: scope})

        # Get active milestones for the project
        active_milestones = get_active_milestones(project.id, scope)

        following = false
        followers_count = 0

        {:ok,
         socket
         |> assign(:project, project)
         |> assign(:chats, chats)
         |> assign(:current_chat, nil)
         |> assign(:current_section, :info)
         |> assign(:events, events)
         |> assign(:active_milestones, active_milestones)
         |> assign(:following, following)
         |> assign(:pages, pages)
         |> assign(:followers_count, followers_count)
         |> assign(:contact_modal_open, false)
         |> assign(:page_title, "Project Info - #{project.title}")}
    end
  end

  def handle_event("toggle-follow", _params, socket) do
    following = !socket.assigns.following
    followers_count = socket.assigns.followers_count + if following, do: 1, else: -1

    flash_message = if following, do: "Now following this project!", else: "Unfollowed project"

    {:noreply,
     socket
     |> assign(:following, following)
     |> assign(:followers_count, followers_count)
     |> put_flash(:info, flash_message)}
  end

  def handle_event("open-contact-modal", _params, socket) do
    {:noreply, assign(socket, :contact_modal_open, true)}
  end

  def handle_event("close-contact-modal", _params, socket) do
    {:noreply, assign(socket, :contact_modal_open, false)}
  end

  # Handle left menu events
  def handle_info({:chat_selected, chat_id}, socket) do
    case Enum.find(socket.assigns.chats, &(&1.id == chat_id)) do
      nil ->
        {:noreply, socket}

      _chat ->
        {:noreply, push_navigate(socket, to: ~p"/project/#{socket.assigns.project.id}/channels")}
    end
  end

  def handle_info({:section_changed, :chat}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/project/#{socket.assigns.project.id}/channels")}
  end

  def handle_info({:section_changed, :milestones}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/project/#{socket.assigns.project.id}/milestones")}
  end

  def handle_info({:section_changed, :info}, socket) do
    # Already on info page
    {:noreply, socket}
  end

  def handle_info(:open_new_channel_modal, socket) do
    {:noreply, push_navigate(socket, to: ~p"/project/#{socket.assigns.project.id}/channels")}
  end

  def handle_info(:close_contact_modal, socket) do
    {:noreply, assign(socket, :contact_modal_open, false)}
  end

  def render(assigns) do
    ~H"""
    <div class="project-page min-h-screen bg-gradient-to-br from-base-100 to-base-200">
      <div class="flex h-screen">
        <!-- Left Menu -->
        <.live_component
          module={LeftMenu}
          pages={@pages}
          id="left-menu"
          project={@project}
          current_scope={@current_scope}
          current_section={@current_section}
          chats={@chats}
          current_chat={@current_chat}
          active_milestones={@active_milestones}
        />
        
    <!-- Main Content Area -->
        <div class="flex-1 flex flex-col">
          <!-- Header -->
          <div class="p-6 border-b border-base-200 bg-base-100">
            <div class="flex items-center justify-between">
              <div>
                <h1 class="text-2xl font-bold text-base-content">Project Information</h1>
                <p class="text-base-content/70 mt-1">
                  Detailed information about <span class="font-medium">{@project.title}</span>
                </p>
              </div>
              <%= if ProjectPermissions.can_update_project?(@project, @current_scope) do %>
                <.link navigate={~p"/project/#{@project.id}/edit"} class="btn btn-primary btn-sm">
                  <.icon name="hero-pencil-square" class="w-4 h-4 mr-2" /> Edit Project
                </.link>
              <% end %>
            </div>
          </div>
          
    <!-- Content -->
          <div class="flex-1 overflow-y-auto">
            <div class="mx-auto p-6">
              <!-- Project Overview Card -->
              <div class="card bg-base-100 shadow-lg mb-6">
                <div class="card-body">
                  <div class="flex items-start justify-between mb-4">
                    <div class="flex-1">
                      <h1 class="text-3xl font-bold mb-2 bg-gradient-to-r from-primary to-accent bg-clip-text text-transparent">
                        {@project.title}
                      </h1>
                      <div class="flex gap-2 mb-4">
                        <ProjectStatusBadge.project_status_badge project={@project} />

                        <span class="badge badge-accent">
                          {String.capitalize(to_string(@project.visibility))}
                        </span>
                      </div>
                    </div>
                    <!-- Action Buttons -->
                    <div class="flex flex-col gap-2">
                      <%= unless ProjectPermissions.can_update_project?(@project, @current_scope) or @current_scope == nil do %>
                        <button class="btn btn-primary btn-sm" phx-click="open-contact-modal">
                          <.icon name="hero-envelope" class="w-4 h-4 mr-2" /> Contact Owner
                        </button>
                        <button
                          class={"btn btn-secondary btn-sm #{if @following, do: "btn-active", else: ""}"}
                          phx-click="toggle-follow"
                        >
                          <.icon name="hero-bookmark" class="w-4 h-4 mr-2" />
                          {if @following, do: "Following", else: "Follow Project"}
                        </button>
                      <% end %>
                    </div>
                  </div>

                  <div class="mb-6">
                    <h2 class="text-lg font-semibold mb-2">Description</h2>
                    <p class="text-base-content/90 leading-relaxed">{@project.description}</p>
                  </div>
                </div>
              </div>
              
    <!-- Technical Details Grid -->
              <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
                <!-- Tech Stack Card -->
                <div class="card bg-base-100 shadow-lg">
                  <div class="card-body">
                    <h2 class="card-title text-lg font-semibold mb-4">
                      <.icon name="hero-code-bracket" class="w-5 h-5" /> Tech Stack
                    </h2>
                    <div class="flex flex-wrap gap-2">
                      <%= for tag <- @project.tags do %>
                        <div class="badge badge-outline badge-secondary">{tag}</div>
                      <% end %>
                      <%= if Enum.empty?(@project.tags) do %>
                        <p class="text-base-content/70 italic">No tech stack specified yet</p>
                      <% end %>
                    </div>
                  </div>
                </div>
                
    <!-- Project Needs Card -->
                <div class="card bg-base-100 shadow-lg">
                  <div class="card-body">
                    <h2 class="card-title text-lg font-semibold mb-4">
                      <.icon name="hero-user-plus" class="w-5 h-5" /> Project Needs
                    </h2>
                    <div class="flex flex-wrap gap-2">
                      <%= for need <- @project.needs do %>
                        <div class="badge badge-outline badge-accent">{need}</div>
                      <% end %>
                      <%= if Enum.empty?(@project.needs) do %>
                        <p class="text-base-content/70 italic">No specific needs listed</p>
                      <% end %>
                    </div>
                  </div>
                </div>
                
    <!-- Business Area Card -->
                <div class="card bg-base-100 shadow-lg">
                  <div class="card-body">
                    <h2 class="card-title text-lg font-semibold mb-4">
                      <.icon name="hero-building-office" class="w-5 h-5" /> Business Area
                    </h2>
                    <div class="flex flex-wrap gap-2">
                      <%= for domain <- @project.business_domains do %>
                        <div class="badge badge-outline badge-accent">{domain}</div>
                      <% end %>
                      <%= if Enum.empty?(@project.business_domains) do %>
                        <p class="text-base-content/70 italic">No specific business areas listed</p>
                      <% end %>
                    </div>
                  </div>
                </div>
                
    <!-- Repository Card -->
                <%= if @project.repository_url do %>
                  <div class="card bg-base-100 shadow-lg">
                    <div class="card-body">
                      <h2 class="card-title text-lg font-semibold mb-4">
                        <.icon name="hero-code-bracket-square" class="w-5 h-5" /> Repository
                      </h2>
                      <a
                        href={@project.repository_url}
                        target="_blank"
                        rel="noopener noreferrer"
                        class="btn btn-outline btn-sm"
                      >
                        <.icon name="hero-arrow-top-right-on-square" class="w-4 h-4 mr-2" />
                        View Repository
                      </a>
                    </div>
                  </div>
                <% end %>
              </div>
              
    <!-- Active Milestones -->
              <%= unless Enum.empty?(@active_milestones) do %>
                <div class="card bg-base-100 shadow-lg mb-6">
                  <div class="card-body">
                    <div class="flex items-center justify-between mb-4">
                      <h2 class="card-title text-lg font-semibold">
                        <.icon name="hero-flag" class="w-5 h-5" /> Active Milestones
                      </h2>
                      <.link
                        navigate={~p"/project/#{@project.id}/milestones"}
                        class="btn btn-ghost btn-sm"
                      >
                        View All <.icon name="hero-arrow-right" class="w-4 h-4 ml-1" />
                      </.link>
                    </div>
                    <div class="space-y-3">
                      <%= for milestone <- Enum.take(@active_milestones, 3) do %>
                        <.link
                          navigate={~p"/project/#{@project.id}/milestones/#{milestone.id}/edit"}
                          class="block"
                        >
                          <div class="flex items-start gap-3 p-3 bg-base-50 rounded-lg border border-base-200 hover:bg-base-100 hover:border-primary/30 hover:shadow-md transition-all duration-200 cursor-pointer">
                            <div class="w-3 h-3 bg-primary rounded-full mt-2 flex-shrink-0"></div>
                            <div class="flex-1">
                              <div class="flex items-center gap-2 mb-1">
                                <h3 class="font-medium text-base-content group-hover:text-primary transition-colors">
                                  {milestone.title}
                                </h3>
                                <span class="badge badge-primary badge-xs">Active</span>
                              </div>
                              <%= if milestone.description do %>
                                <p class="text-sm text-base-content/70 mb-2">
                                  {milestone.description}
                                </p>
                              <% end %>
                              <%= if milestone.due_date do %>
                                <div class="flex items-center gap-1 text-xs text-base-content/60">
                                  <.icon name="hero-calendar" class="w-3 h-3" />
                                  <span>Due: {format_milestone_date(milestone.due_date)}</span>
                                  <%= if Date.compare(NaiveDateTime.to_date(milestone.due_date), Date.utc_today()) == :lt do %>
                                    <span class="text-error font-medium">(Overdue)</span>
                                  <% end %>
                                </div>
                              <% end %>
                            </div>
                          </div>
                        </.link>
                      <% end %>
                    </div>
                  </div>
                </div>
              <% end %>
              
    <!-- Project Owner & Community -->
              <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
                <!-- Project Owner Card -->
                <div class="card bg-base-100 shadow-lg">
                  <div class="card-body">
                    <h2 class="card-title text-lg font-semibold mb-4">
                      <.icon name="hero-user" class="w-5 h-5" /> Project Owner
                    </h2>
                    <div class="flex items-center gap-3">
                      <Avatar.avatar name={@project.owner.name} size={:lg} />
                      <div>
                        <h3 class="font-medium text-lg">{@project.owner.name}</h3>
                        <p class="text-base-content/70">{@project.owner.email}</p>
                      </div>
                    </div>
                  </div>
                </div>
                
    <!-- Community Card -->
                <div class="card bg-base-100 shadow-lg">
                  <div class="card-body">
                    <h2 class="card-title text-lg font-semibold mb-4">
                      <.icon name="hero-users" class="w-5 h-5" /> Community
                    </h2>
                    <div class="flex items-center gap-2 text-base-content/70">
                      <.icon name="hero-users" class="w-5 h-5" />
                      <span class="font-medium">{@followers_count} followers</span>
                    </div>
                  </div>
                </div>
              </div>
              
    <!-- Project Timeline -->
              <%= unless Enum.empty?(@events) do %>
                <div class="card bg-base-100 shadow-lg">
                  <div class="card-body">
                    <h2 class="card-title text-lg font-semibold mb-4">
                      <.icon name="hero-clock" class="w-5 h-5" /> Project Timeline
                    </h2>
                    <ul class="timeline timeline-snap-icon timeline-compact timeline-vertical">
                      <%= for {event, index} <- Enum.with_index(@events) do %>
                        <li>
                          <%= if index > 0 do %>
                            <hr class="bg-primary" />
                          <% end %>
                          <div class="timeline-middle">
                            <.icon name="hero-check-circle" class="w-5 h-5 text-primary" />
                          </div>
                          <div class="timeline-start md:text-end mb-2">
                            <time class="text-sm opacity-60">
                              {Calendar.strftime(event.inserted_at, "%B %d, %Y at %I:%M %p")}
                            </time>
                            <div class="text-base font-medium">{event_title(event)}</div>
                          </div>
                          <%= if index < length(@events) - 1 do %>
                            <hr class="bg-primary" />
                          <% end %>
                        </li>
                      <% end %>
                    </ul>
                  </div>
                </div>
              <% end %>
            </div>
          </div>
        </div>
      </div>
      
    <!-- Contact Modal -->
      <%= if @contact_modal_open do %>
        <.live_component
          module={WeCraftWeb.Projects.Components.ContactFormComponent}
          id="contact-form"
          owner={@project.owner}
        />
      <% end %>
    </div>
    """
  end

  defp event_title(%ProjectEvent{event_type: "project_created"}), do: "Project Created"

  defp event_title(%ProjectEvent{
         event_type: "milestone_active",
         metadata: %{"milestone_title" => title}
       }),
       do: "Milestone \"#{title}\" is active"

  defp event_title(%ProjectEvent{
         event_type: "milestone_completed",
         metadata: %{"milestone_title" => title}
       }),
       do: "Milestone \"#{title}\" is completed"

  defp event_title(%ProjectEvent{
         event_type: "project_status_updated"
       }),
       do: "Project Status Updated"

  defp event_title(%ProjectEvent{} = event), do: event.event_type

  defp get_active_milestones(project_id, scope) do
    case Milestones.list_project_milestones(%{project_id: project_id, scope: scope}) do
      {:ok, milestones} ->
        milestones
        |> Enum.filter(&(&1.status == :active))

      {:error, _} ->
        []
    end
  end

  defp format_milestone_date(nil), do: "No date set"

  defp format_milestone_date(datetime) do
    datetime
    |> NaiveDateTime.to_date()
    |> Calendar.strftime("%B %d, %Y")
  end
end
