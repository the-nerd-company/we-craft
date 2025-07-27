defmodule WeCraftWeb.Profiles.ShowProfile do
  @moduledoc """
  LiveView for displaying user profile.
  """
  use WeCraftWeb, :live_view

  alias WeCraft.Profiles
  alias WeCraft.Profiles.ProfilePermissions
  alias WeCraftWeb.Components.Avatar

  def mount(%{"user_id" => user_id}, _session, socket) do
    case Profiles.get_profile_by_user_id(user_id) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Profile not found")
         |> push_navigate(to: ~p"/")}

      profile ->
        socket =
          socket
          |> assign(:profile, profile)
          |> assign(:page_title, "#{profile.user.name || profile.user.email}'s Profile")

        {:ok, socket}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-base-100 to-base-200 p-6">
      <div class="mx-auto max-w-4xl">
        <!-- Profile Header -->
        <div class="bg-base-100 p-8 rounded-lg shadow-sm mb-6">
          <div class="flex items-start gap-6">
            <div class="flex-shrink-0">
              <Avatar.avatar name={@profile.user.name || "Anonymous User"} class="w-24 h-24 text-2xl" />
            </div>

            <div class="flex-1">
              <h1 class="text-3xl font-bold mb-2">
                {@profile.user.name || "Anonymous User"}
              </h1>

              <div class="flex items-center gap-4 mb-4">
                <span class="text-base-content/70">
                  <.icon name="hero-calendar" class="size-4 inline mr-1" />
                  Joined {Calendar.strftime(@profile.user.inserted_at, "%B %Y")}
                </span>
              </div>

              <%= if ProfilePermissions.can_edit_profile?(@profile, @current_scope) do %>
                <.link navigate={~p"/profile/edit"} class="btn btn-primary btn-sm">
                  <.icon name="hero-pencil" class="size-4 mr-2" /> Edit Profile
                </.link>
              <% end %>
            </div>
          </div>
        </div>
        
    <!-- Bio Section -->
        <div class="bg-base-100 p-8 rounded-lg shadow-sm">
          <h2 class="text-xl font-semibold mb-4">About</h2>

          <%= if @profile.bio && @profile.bio != "Tell us about yourself..." do %>
            <div class="prose prose-base max-w-none">
              <p class="whitespace-pre-wrap">{@profile.bio}</p>
            </div>
          <% else %>
            <div class="text-center py-8 text-base-content/60">
              <.icon name="hero-user" class="size-12 mx-auto mb-4 opacity-50" />
              <p>This user hasn't added a bio yet.</p>

              <%= if @profile.user.id == @current_scope.user.id do %>
                <.link navigate={~p"/profile/edit"} class="btn btn-outline btn-sm mt-4">
                  Add Bio
                </.link>
              <% end %>
            </div>
          <% end %>
        </div>
        
    <!-- Skills Section -->
        <div class="bg-base-100 p-8 rounded-lg shadow-sm mt-6">
          <h2 class="text-xl font-semibold mb-4">Technical Skills</h2>
          <div class="flex flex-wrap gap-2">
            <%= for skill <- @profile.skills do %>
              <div class="badge badge-outline badge-secondary">{skill}</div>
            <% end %>
          </div>
        </div>
        
    <!-- Offers Section -->
        <div class="bg-base-100 p-8 rounded-lg shadow-sm mt-6">
          <h2 class="text-xl font-semibold mb-4">What I Can Offer</h2>
          <div class="flex flex-wrap gap-2">
            <%= for offer <- @profile.offers do %>
              <div class="badge badge-outline badge-accent">{offer}</div>
            <% end %>
          </div>
        </div>
        
    <!-- Projects Section (Future Enhancement) -->
        <!--
        <div class="bg-base-100 p-8 rounded-lg shadow-sm mt-6">
          <h2 class="text-xl font-semibold mb-4">Projects</h2>
          <p class="text-base-content/60">Projects will be displayed here in the future.</p>
        </div>
        -->
      </div>
    </div>
    """
  end
end
