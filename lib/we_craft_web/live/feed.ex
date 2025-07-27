defmodule WeCraftWeb.Feed do
  @moduledoc """
  LiveView for displaying the project activity feed.
  """
  use WeCraftWeb, :live_view

  alias WeCraft.Projects

  def mount(_params, _session, socket) do
    # Get the latest 50 events for the feed
    {:ok, events} = Projects.get_feed(%{limit: 50})

    # Schedule periodic refresh every 30 seconds
    _ =
      if connected?(socket) do
        Process.send_after(self(), :refresh_feed, 30_000)
      end

    {:ok, assign(socket, events: events, page_title: "Activity Feed", feed_active: true)}
  end

  def handle_info(:refresh_feed, socket) do
    # Only refresh if feed is active
    if socket.assigns.feed_active do
      {:ok, events} = Projects.get_feed(%{limit: 50})

      # Schedule next refresh only if feed is still active
      Process.send_after(self(), :refresh_feed, 30_000)

      {:noreply, assign(socket, :events, events)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("refresh_feed", _params, socket) do
    {:ok, events} = Projects.get_feed(%{limit: 50})
    {:noreply, assign(socket, :events, events)}
  end

  def handle_event("toggle_feed", _params, socket) do
    new_feed_state = !socket.assigns.feed_active

    # If we're starting the feed, schedule the next refresh
    _ =
      if new_feed_state do
        _ = Process.send_after(self(), :refresh_feed, 30_000)
      end

    {:noreply, assign(socket, :feed_active, new_feed_state)}
  end

  def render(assigns) do
    ~H"""
    <div class="feed-page min-h-screen bg-gradient-to-br from-base-100 to-base-200">
      <div class="container mx-auto px-4 py-6">
        <div class="text-center mb-6">
          <div class="flex items-center justify-center gap-3 mb-4">
            <h1 class="text-3xl font-bold bg-gradient-to-r from-primary to-accent bg-clip-text text-transparent">
              Activity Feed
            </h1>
            <div class="flex gap-2">
              <button
                phx-click="refresh_feed"
                class="btn btn-ghost btn-circle btn-sm tooltip tooltip-bottom"
                data-tip="Refresh feed"
              >
                <.icon name="hero-arrow-path" class="w-5 h-5" />
              </button>
              <button
                phx-click="toggle_feed"
                class={"btn btn-ghost btn-circle btn-sm tooltip tooltip-bottom #{if @feed_active, do: "text-success", else: "text-error"}"}
                data-tip={if @feed_active, do: "Stop auto-refresh", else: "Start auto-refresh"}
              >
                <%= if @feed_active do %>
                  <.icon name="hero-pause" class="w-5 h-5" />
                <% else %>
                  <.icon name="hero-play" class="w-5 h-5" />
                <% end %>
              </button>
            </div>
          </div>
          <p class="text-base text-base-content/80">
            Stay updated with the latest project activities in the community.
          </p>
          <div class="mt-2">
            <%= if @feed_active do %>
              <div class="flex items-center justify-center gap-2 text-xs text-success">
                <div class="w-2 h-2 bg-success rounded-full animate-pulse"></div>
                <span>Auto-refresh active</span>
              </div>
            <% else %>
              <div class="flex items-center justify-center gap-2 text-xs text-base-content/60">
                <div class="w-2 h-2 bg-base-content/40 rounded-full"></div>
                <span>Auto-refresh paused</span>
              </div>
            <% end %>
          </div>
        </div>

        <%= if @events == [] do %>
          <div class="text-center py-12">
            <div class="mb-6 p-4 bg-base-200 rounded-full w-fit mx-auto">
              <.icon name="hero-rss" class="size-12 text-primary" />
            </div>
            <h3 class="text-xl font-semibold mb-2">No activity yet</h3>
            <p class="text-base-content/70 mb-6 max-w-md mx-auto">
              Check back later for the latest project updates and activities from the community.
            </p>
          </div>
        <% else %>
          <div class="max-w-2xl mx-auto">
            <div class="space-y-4">
              <%= for event <- @events do %>
                <div class="card bg-base-100 shadow hover:shadow-md transition-shadow duration-200">
                  <div class="card-body p-4">
                    <div class="flex items-start gap-3">
                      <!-- Event Icon -->
                      <div class="flex-shrink-0">
                        <div class="p-2 bg-primary/10 rounded-full">
                          <%= case event.event_type do %>
                            <% "project_created" -> %>
                              <.icon name="hero-plus-circle" class="w-5 h-5 text-primary" />
                            <% "project_updated" -> %>
                              <.icon name="hero-pencil-square" class="w-5 h-5 text-accent" />
                            <% "milestone_created" -> %>
                              <.icon name="hero-flag" class="w-5 h-5 text-success" />
                            <% "milestone_completed" -> %>
                              <.icon name="hero-check-circle" class="w-5 h-5 text-success" />
                            <% _ -> %>
                              <.icon name="hero-bell" class="w-5 h-5 text-info" />
                          <% end %>
                        </div>
                      </div>
                      
    <!-- Event Content -->
                      <div class="flex-1 min-w-0">
                        <!-- Event Title and Time -->
                        <div class="flex items-center justify-between mb-2">
                          <h3 class="text-base font-semibold text-base-content">
                            {format_event_title(event)}
                          </h3>
                          <time class="text-xs text-base-content/60 flex-shrink-0">
                            {format_time_ago(event.inserted_at)}
                          </time>
                        </div>
                        
    <!-- Project Name - More Subtle -->
                        <%= if event.project do %>
                          <div class="mb-2">
                            <.link navigate={~p"/project/#{event.project.id}"} class="group">
                              <span class="text-lg font-medium text-primary group-hover:text-primary/80 transition-colors duration-200">
                                {event.project.title}
                              </span>
                            </.link>
                          </div>
                        <% end %>
                        
    <!-- Event Description -->
                        <p class="text-sm text-base-content/70 mb-3">
                          {format_event_description(event)}
                        </p>
                        
    <!-- Action Button -->
                        <%= if event.project do %>
                          <.link
                            navigate={~p"/project/#{event.project.id}"}
                            class="btn btn-primary btn-xs"
                          >
                            <.icon name="hero-arrow-right" class="w-3 h-3 mr-1" /> View
                          </.link>
                        <% end %>
                      </div>
                    </div>
                  </div>
                </div>
              <% end %>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp format_event_title(event) do
    case event.event_type do
      "project_created" -> "New Project Created"
      "project_updated" -> "Project Updated"
      "milestone_created" -> "New Milestone Added"
      "milestone_completed" -> "Milestone Completed"
      _ -> "Project Activity"
    end
  end

  defp format_event_description(event) do
    case event.event_type do
      "project_created" ->
        "A new project has been created and is now available to explore."

      "project_updated" ->
        "The project has been updated with new information."

      "milestone_created" ->
        milestone_title = get_in(event.metadata, ["title"]) || "milestone"
        "A new milestone '#{milestone_title}' was added to this project."

      "milestone_completed" ->
        milestone_title = get_in(event.metadata, ["title"]) || "milestone"
        "Milestone '#{milestone_title}' has been completed."

      _ ->
        "New activity in this project."
    end
  end

  defp format_time_ago(datetime) do
    now = DateTime.utc_now()

    # Convert NaiveDateTime to DateTime if needed
    datetime_utc =
      case datetime do
        %DateTime{} = dt -> dt
        %NaiveDateTime{} = ndt -> DateTime.from_naive!(ndt, "Etc/UTC")
      end

    diff_seconds = DateTime.diff(now, datetime_utc, :second)

    cond do
      diff_seconds < 60 ->
        "#{diff_seconds}s ago"

      diff_seconds < 3600 ->
        minutes = div(diff_seconds, 60)
        "#{minutes}m ago"

      diff_seconds < 86_400 ->
        hours = div(diff_seconds, 3600)
        "#{hours}h ago"

      diff_seconds < 2_592_000 ->
        days = div(diff_seconds, 86_400)
        "#{days}d ago"

      true ->
        datetime_utc
        |> DateTime.to_date()
        |> Date.to_string()
    end
  end
end
