defmodule WeCraftWeb.Components.LeftMenu do
  @moduledoc """
  A Slack-like left menu component for project navigation.
  This component provides navigation between different project sections like chats and milestones.
  """
  use WeCraftWeb, :live_component

  alias WeCraft.CRM.CRMPermissions
  alias WeCraft.Projects.Project
  alias WeCraft.Projects.ProjectPermissions
  alias WeCraft.Tickets.TicketsPermissions

  alias WeCraft.{Chats, Milestones, Pages, Projects}

  def load_menu_data(socket, %{"project_id" => project_id}) do
    scope = socket.assigns.current_scope

    socket =
      case Map.has_key?(socket.assigns, :project) do
        false ->
          {:ok, project} = Projects.get_project(%{project_id: project_id, scope: scope})
          assign(socket, :project, project)

        true ->
          socket
      end

    # Get chats for the left menu
    {:ok, chats} = Chats.list_project_chats(%{project_id: socket.assigns.project.id})
    {:ok, pages} = Pages.list_project_pages(%{project: socket.assigns.project, scope: scope})

    # Load milestones for the project
    milestones = load_project_milestones(socket.assigns.project.id, scope)

    # Get active milestones for the left menu
    active_milestones =
      milestones
      |> Enum.filter(&(&1.status == :active))

    {:ok,
     socket
     |> assign(:chats, chats)
     |> assign(:current_chat, nil)
     |> assign(:current_section, :milestones)
     |> assign(:milestones, milestones)
     |> assign(:pages, pages)
     |> assign(:active_milestones, active_milestones)
     |> assign(:editing_task, nil)
     |> assign(:task_form, nil)
     |> assign(:page_title, "#{socket.assigns.project.title}")}
  end

  defp load_project_milestones(project_id, scope) do
    case Milestones.list_project_milestones(%{project_id: project_id, scope: scope}) do
      {:ok, milestones} -> milestones
      {:error, _} -> []
    end
  end

  def mount(socket) do
    {:ok, assign(socket, :collapsed_sections, %{})}
  end

  def update(assigns, socket) do
    # Set default values for all assigns that might not be provided

    {:ok,
     socket
     |> assign(assigns)
     |> assign(
       :class,
       Map.get(assigns, :class, "w-64 border-r border-base-200 bg-base-50 flex flex-col h-full")
     )
     |> assign(:pages, Map.get(assigns, :pages, []))
     |> assign(:current_page_id, Map.get(assigns, :current_page_id, nil))
     |> assign(:current_section, Map.get(assigns, :current_section, :chat))
     |> assign(:chats, Map.get(assigns, :chats, []))
     |> assign(:current_chat, Map.get(assigns, :current_chat, nil))
     |> assign(:active_milestones, Map.get(assigns, :active_milestones, []))}
  end

  def render(assigns) do
    ~H"""
    <div class={@class}>
      <!-- Project Header -->
      <div class="p-4 border-b border-base-200 bg-primary/5">
        <div class="flex items-center justify-between mb-2">
          <div class="flex items-center gap-2">
            <div class="w-8 h-8 bg-primary rounded-lg flex items-center justify-center text-primary-content font-bold text-sm">
              {String.first(@project.title)}
            </div>
            <div class="flex-1 min-w-0">
              <h2 class="font-semibold text-base-content truncate text-sm">{@project.title}</h2>
              <p class="text-xs text-base-content/70 truncate">
                {status_badge(@project.status)}
              </p>
            </div>
          </div>
          <%= if ProjectPermissions.can_update_project?(@project, @current_scope) do %>
            <div class="dropdown dropdown-end">
              <div tabindex="0" role="button" class="btn btn-ghost btn-sm btn-circle">
                <.icon name="hero-ellipsis-vertical" class="w-4 h-4" />
              </div>
              <ul
                tabindex="0"
                class="menu menu-sm dropdown-content bg-base-100 rounded-box z-[1] mt-3 w-48 p-2 shadow"
              >
                <li>
                  <.link navigate={~p"/project/#{@project.id}/edit"}>
                    <.icon name="hero-pencil-square" class="w-4 h-4" /> Edit Project
                  </.link>
                </li>
              </ul>
            </div>
          <% end %>
        </div>
      </div>
      
    <!-- Navigation Menu -->
      <div class="flex-1 overflow-y-auto">
        <!-- Project Info Section -->
        <div class="p-2">
          <.link
            navigate={~p"/project/#{@project.id}"}
            class={
              "flex items-center gap-2 w-full p-2 hover:bg-base-100 rounded text-sm #{
                if @current_section == :info,
                  do: "bg-primary/10 text-primary font-medium",
                  else: "text-base-content/80"
              }"
            }
          >
            <.icon name="hero-information-circle" class="w-4 h-4" />
            <span>Project Info</span>
          </.link>
        </div>

        <%= if CRMPermissions.can_view_contacts?(%{project: @project, scope: @current_scope}) do %>
          <div class="p-2">
            <.link
              navigate={~p"/project/#{@project.id}/customers"}
              class="flex items-center justify-between w-full p-2 hover:bg-base-100 rounded text-sm font-medium text-base-content/80"
            >
              <div class="flex items-center gap-2">
                <.icon name="hero-users" class="w-4 h-4" />
                <span>Customers</span>
              </div>
            </.link>
          </div>
        <% end %>

        <%= if TicketsPermissions.can_view_tickets?(%{project: @project, scope: @current_scope}) do %>
          <div class="p-2">
            <.link
              navigate={~p"/project/#{@project.id}/tickets"}
              class="flex items-center justify-between w-full p-2 hover:bg-base-100 rounded text-sm font-medium text-base-content/80"
            >
              <div class="flex items-center gap-2">
                <.icon name="hero-ticket" class="w-4 h-4" />
                <span>Tickets</span>
              </div>
            </.link>
          </div>
        <% end %>
        
    <!-- Chat Section -->
        <div class="p-2">
          <button
            phx-click="toggle-section"
            phx-value-section="chats"
            phx-target={@myself}
            class="flex items-center justify-between w-full p-2 hover:bg-base-100 rounded text-sm font-medium text-base-content/80"
          >
            <div class="flex items-center gap-2">
              <.icon
                name={
                  if @collapsed_sections[:chats], do: "hero-chevron-right", else: "hero-chevron-down"
                }
                class="w-3 h-3"
              />
              <.icon name="hero-chat-bubble-left-right" class="w-4 h-4" />
              <span>Channels</span>
            </div>
            <span class="text-xs text-base-content/50">{length(@chats)}</span>
          </button>

          <%= unless @collapsed_sections[:chats] do %>
            <div class="ml-6 mt-1 space-y-1">
              <%= if Enum.empty?(@chats) do %>
                <div class="px-2 py-1 text-xs text-base-content/60">
                  No channels yet
                </div>
              <% else %>
                <%= for chat <- @chats do %>
                  <button
                    phx-click="select-chat"
                    phx-value-chat-id={chat.id}
                    phx-target={@myself}
                    class={
                      "flex items-center gap-2 w-full p-1.5 text-sm hover:bg-base-100 rounded #{
                        if @current_chat && chat.id == @current_chat.id && @current_section == :chat,
                          do: "bg-primary/10 text-primary font-medium"
                      }"
                    }
                  >
                    <.icon name="hero-hashtag" class="w-3 h-3 opacity-60" />
                    <span class="truncate">{get_chat_display_name(chat)}</span>
                    <%= if has_unread_messages?(chat) do %>
                      <div class="w-2 h-2 bg-primary rounded-full ml-auto"></div>
                    <% end %>
                  </button>
                <% end %>
              <% end %>

              <%= if ProjectPermissions.can_update_project?(@project, @current_scope) do %>
                <button
                  phx-click="create-channel"
                  phx-target={@myself}
                  class="flex items-center gap-2 w-full p-1.5 text-sm text-base-content/60 hover:text-base-content hover:bg-base-100 rounded"
                >
                  <.icon name="hero-plus" class="w-3 h-3" />
                  <span>Add channel</span>
                </button>
              <% end %>
            </div>
          <% end %>
        </div>
        
    <!-- Milestones Section -->
        <div class="p-2">
          <button
            phx-click="toggle-section"
            phx-value-section="milestones"
            phx-target={@myself}
            class="flex items-center justify-between w-full p-2 hover:bg-base-100 rounded text-sm font-medium text-base-content/80"
          >
            <div class="flex items-center gap-2">
              <.icon
                name={
                  if @collapsed_sections[:milestones],
                    do: "hero-chevron-right",
                    else: "hero-chevron-down"
                }
                class="w-3 h-3"
              />
              <.icon name="hero-flag" class="w-4 h-4" />
              <span>Milestones</span>
            </div>
          </button>

          <%= unless @collapsed_sections[:milestones] do %>
            <div class="ml-6 mt-1 space-y-1">
              <!-- All Milestones Link -->
              <.link
                navigate={~p"/project/#{@project.id}/milestones"}
                class={
                  "flex items-center gap-2 w-full p-1.5 text-sm hover:bg-base-100 rounded #{
                    if @current_section == :milestones,
                      do: "bg-primary/10 text-primary font-medium",
                      else: "text-base-content/80"
                  }"
                }
              >
                <.icon name="hero-list-bullet" class="w-3 h-3 opacity-60" />
                <span>All milestones</span>
              </.link>
              
    <!-- Active Milestones Subsection -->
              <%= unless Enum.empty?(@active_milestones) do %>
                <div class="mt-2">
                  <div class="flex items-center gap-2 px-1.5 py-1 text-xs font-medium text-base-content/60 uppercase tracking-wide">
                    <.icon name="hero-clock" class="w-3 h-3" />
                    <span>Active ({length(@active_milestones)})</span>
                  </div>
                  <div class="space-y-1 mt-1">
                    <%= for milestone <- Enum.take(@active_milestones, 5) do %>
                      <.link
                        navigate={~p"/project/#{@project.id}/milestones/#{milestone.id}/edit"}
                        class="flex items-start gap-2 w-full p-1.5 text-sm hover:bg-base-100 rounded group ml-2"
                      >
                        <div class="w-2 h-2 bg-primary rounded-full mt-1.5 flex-shrink-0"></div>
                        <div class="flex-1 min-w-0">
                          <p class="truncate font-medium text-base-content group-hover:text-primary">
                            {milestone.title}
                          </p>
                          <%= if milestone.due_date do %>
                            <p class="text-xs text-base-content/60 truncate">
                              Due: {format_milestone_date_short(milestone.due_date)}
                              <%= if Date.compare(NaiveDateTime.to_date(milestone.due_date), Date.utc_today()) == :lt do %>
                                <span class="text-error">•</span>
                              <% end %>
                            </p>
                          <% end %>
                        </div>
                      </.link>
                    <% end %>
                  </div>
                </div>
              <% end %>
              <!-- New Milestone Link -->
              <%= if ProjectPermissions.can_update_project?(@project, @current_scope) do %>
                <.link
                  navigate={~p"/project/#{@project.id}/milestones/new"}
                  class="flex items-center gap-2 w-full p-1.5 text-sm text-base-content/60 hover:text-base-content hover:bg-base-100 rounded"
                >
                  <.icon name="hero-plus" class="w-3 h-3" />
                  <span>New milestone</span>
                </.link>
              <% end %>
            </div>
          <% end %>
        </div>

        <%!-- <%= if Application.get_env(:we_craft, :env) in [:dev, :test] do %> --%>
        <div class="p-2">
          <button
            phx-click="toggle-section"
            phx-value-section="pages"
            phx-target={@myself}
            class="flex items-center justify-between w-full p-2 hover:bg-base-100 rounded text-sm font-medium text-base-content/80"
          >
            <div class="flex items-center gap-2">
              <.icon
                name={
                  if @collapsed_sections[:pages],
                    do: "hero-chevron-right",
                    else: "hero-chevron-down"
                }
                class="w-3 h-3"
              />
              <.icon name="hero-book-open" class="w-4 h-4" />
              <span>Pages</span>
            </div>
            <span class="text-xs text-base-content/50">{length(@pages)}</span>
          </button>

          <%= unless @collapsed_sections[:pages] do %>
            <div class="ml-6 mt-1 space-y-1">
              <%= if Enum.empty?(@pages) do %>
                <div class="px-2 py-1 text-xs text-base-content/60">
                  No Page Yet
                </div>
              <% else %>
                <%= for page <- @pages do %>
                  <button
                    phx-click="select-page"
                    phx-value-page-id={page.id}
                    phx-target={@myself}
                    class={"flex items-center gap-2 w-full p-1.5 text-sm hover:bg-base-100 rounded #{
                    if Map.has_key?(assigns, :current_page_id) && page.id == @current_page_id,
                    do: "bg-primary/10 text-primary font-medium"
                  }"}
                  >
                    <.icon name="hero-document" class="w-3 h-3 opacity-60" />
                    <span class="truncate">{page.title}</span>
                  </button>
                <% end %>
              <% end %>

              <%= if WeCraft.Pages.PagePermissions.can_create_page?(%{project: @project, scope: @current_scope}) do %>
                <.link
                  navigate={~p"/project/#{@project.id}/pages/new"}
                  class="flex items-center gap-2 w-full p-1.5 text-sm text-base-content/60 hover:text-base-content hover:bg-base-100 rounded"
                >
                  <.icon name="hero-plus" class="w-3 h-3" />
                  <span>Create Page</span>
                </.link>
              <% end %>
            </div>
          <% end %>
        </div>
        <%!-- <% end %> --%>
      </div>
      
    <!-- User Panel (Bottom) -->
      <div class="p-3 border-t border-base-200 bg-base-100/50">
        <%= if @current_scope && @current_scope.user do %>
          <div class="flex items-center gap-2">
            <div class="w-8 h-8 bg-success rounded-lg flex items-center justify-center text-success-content font-bold text-xs relative">
              {WeCraftWeb.Components.Avatar.avatar_initials(
                @current_scope.user.name || @current_scope.user.email
              )}
              <div class="absolute -bottom-0.5 -right-0.5 w-3 h-3 bg-success border-2 border-base-100 rounded-full">
              </div>
            </div>
            <div class="flex-1 min-w-0">
              <p class="text-sm font-medium text-base-content truncate">
                {@current_scope.user.name || String.split(@current_scope.user.email, "@") |> hd()}
              </p>
              <p class="text-xs text-base-content/60">Online</p>
            </div>
          </div>
        <% else %>
          <div class="text-center">
            <.link href={~p"/users/log-in"} class="btn btn-primary btn-sm w-full">
              Sign In
            </.link>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  def handle_event("toggle-section", %{"section" => section}, socket) do
    section_atom = String.to_atom(section)
    collapsed_sections = socket.assigns.collapsed_sections

    new_collapsed_sections =
      Map.put(collapsed_sections, section_atom, !Map.get(collapsed_sections, section_atom, false))

    {:noreply, assign(socket, :collapsed_sections, new_collapsed_sections)}
  end

  def handle_event("select-chat", %{"chat-id" => chat_id}, socket) do
    # Send the event to the parent LiveView to handle chat selection
    send(self(), {:chat_selected, String.to_integer(chat_id)})
    send(self(), {:section_changed, :chat})
    {:noreply, socket}
  end

  def handle_event("select-page", %{"page-id" => page_id}, socket) do
    {:noreply,
     push_navigate(socket, to: ~p"/project/#{socket.assigns.project.id}/pages/#{page_id}")}
  end

  def handle_event("create-channel", _params, socket) do
    # Send event to parent to open the new channel modal
    send(self(), :open_new_channel_modal)
    {:noreply, socket}
  end

  defp get_chat_display_name(chat) do
    cond do
      chat.is_main -> "general"
      chat.name && chat.name != "" -> chat.name
      true -> "chat-#{chat.id}"
    end
  end

  defp has_unread_messages?(_chat) do
    # For now, return false - will be implemented with real-time message tracking
    false
  end

  defp status_badge(status) do
    label = Project.status_display(status)

    case status do
      :idea -> "💡 #{label}"
      :in_dev -> "🚧 #{label}"
      :private_beta -> "👥 #{label}"
      :public_beta -> "🌐 #{label}"
      :live -> "🚀 #{label}"
      _ -> "Unknown"
    end
  end

  defp format_milestone_date_short(nil), do: "No date"

  defp format_milestone_date_short(datetime) do
    date = NaiveDateTime.to_date(datetime)
    today = Date.utc_today()

    case Date.diff(date, today) do
      0 -> "Today"
      1 -> "Tomorrow"
      days when days > 0 and days <= 7 -> "#{days}d"
      days when days > 7 -> Calendar.strftime(date, "%m/%d")
      days when days < 0 -> "#{abs(days)}d ago"
    end
  end
end
