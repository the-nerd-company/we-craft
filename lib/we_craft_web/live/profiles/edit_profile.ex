defmodule WeCraftWeb.Profiles.EditProfile do
  @moduledoc """
  LiveView for editing user profile.
  """
  use WeCraftWeb, :live_view

  alias Phoenix.HTML.Form
  alias WeCraft.Profiles
  alias WeCraft.Profiles.Profile
  alias WeCraft.Projects.{NeedsTags, TechnicalTags}

  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user

    case Profiles.get_or_create_profile_for_user(user) do
      {:ok, profile} ->
        changeset = Profile.update_changeset(profile, %{})

        socket =
          socket
          |> assign(:profile, profile)
          |> assign(:changeset, changeset)
          |> assign(:page_title, "Edit Profile")
          |> assign(:technical_tags, TechnicalTags.all_tags_by_category())
          |> assign(:needs_tags, NeedsTags.all_needs())
          |> assign(:tag_filter, "")

        {:ok, socket}

      {:error, changeset} ->
        {:ok, put_flash(socket, :error, "Unable to load profile: #{inspect(changeset.errors)}")}
    end
  end

  def handle_event("validate", %{"profile" => profile_params}, socket) do
    changeset =
      socket.assigns.profile
      |> Profile.update_changeset(profile_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"profile" => profile_params}, socket) do
    case Profiles.update_user_profile(%{project: socket.assigns.profile, attrs: profile_params}) do
      {:ok, profile} ->
        socket =
          socket
          |> put_flash(:info, "Profile updated successfully!")
          |> assign(:profile, profile)
          |> assign(:changeset, Profile.update_changeset(profile, %{}))

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  def handle_event("add_tag", %{"tag" => tag, "field" => field, "category" => category}, socket) do
    add_tag_to_field(tag, field, category, socket)
  end

  def handle_event(
        "remove_tag",
        %{"tag" => tag, "field" => field, "category" => _category},
        socket
      ) do
    current_changeset = socket.assigns.changeset
    field_name = extract_field_name(field)

    # Get current field value from changeset
    current_field_value =
      case Ecto.Changeset.get_change(current_changeset, field_name) do
        nil ->
          # If no changes, get from data
          case Map.get(current_changeset.data, field_name) do
            nil -> []
            value when is_list(value) -> value
            _ -> []
          end

        value when is_list(value) ->
          value

        _ ->
          []
      end

    # Remove the tag from the list
    updated_value = Enum.reject(current_field_value, &(&1 == tag))

    # Create params with string keys for consistency
    params = %{to_string(field_name) => updated_value}

    # Clear the tag filter and update the form
    socket = assign(socket, :tag_filter, "")
    handle_event("validate", %{"profile" => params}, socket)
  end

  defp add_tag_to_field(tag, field, category, socket) do
    current_changeset = socket.assigns.changeset
    field_name = extract_field_name(field)

    # Get current field value from changeset
    current_field_value =
      case Ecto.Changeset.get_change(current_changeset, field_name) do
        nil ->
          # If no changes, get from data
          case Map.get(current_changeset.data, field_name) do
            nil -> []
            value when is_list(value) -> value
            _ -> []
          end

        value when is_list(value) ->
          value

        _ ->
          []
      end

    # Only add the tag if it's not already in the list
    if Enum.member?(current_field_value, tag) do
      {:noreply, socket}
    else
      # Check if the tag is valid for the category (if applicable)
      if valid_tag_for_category?(tag, field_name, category, socket.assigns) do
        # Update the form with the new tag
        add_normalized_tag(tag, field_name, current_field_value, socket)
      else
        {:noreply, socket}
      end
    end
  end

  # Add a normalized tag to the field value and update the form
  defp add_normalized_tag(tag, field_name, current_field_value, socket) do
    # Ensure tag is normalized (lowercase)
    normalized_tag = String.downcase(tag)

    # Add the new tag to the current value
    updated_value = [normalized_tag | current_field_value]

    # Create params with string keys for consistency
    params = %{to_string(field_name) => updated_value}

    # Update form
    handle_event("validate", %{"profile" => params}, socket)
  end

  # Extract field name from form field path (e.g., "profile[skills]" -> :skills)
  defp extract_field_name(field) do
    field |> String.replace(~r/^profile\[(.+)\]$/, "\\1") |> String.to_existing_atom()
  end

  # Check if tag is valid for the given category
  defp valid_tag_for_category?(tag, field_name, category, assigns) do
    # For skills field with category specified
    cond do
      category && field_name == :skills ->
        all_tags_by_category = assigns.technical_tags
        category_atom = safe_string_to_atom(category)
        category_tags = Map.get(all_tags_by_category, category_atom, [])
        tag in category_tags

      field_name == :offers ->
        needs_tags = assigns.needs_tags
        tag in needs_tags

      true ->
        # Default case - no validation
        true
    end
  end

  # Safely convert string to atom
  defp safe_string_to_atom(string) do
    String.to_existing_atom(string)
  rescue
    ArgumentError -> String.to_atom(string)
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-base-100 to-base-200 p-6">
      <div class="mx-auto max-w-2xl bg-base-100 p-8 rounded-lg shadow-sm">
        <.flash kind={:info} flash={@flash} />
        <.flash kind={:error} flash={@flash} />

        <.header>
          Edit Your Profile
          <:subtitle>
            Update your profile information to help other developers and founders connect with you.
          </:subtitle>
        </.header>

        <.form
          :let={f}
          for={@changeset}
          id="profile-form"
          phx-change="validate"
          phx-submit="save"
          class="mt-8 space-y-6"
        >
          <div>
            <.input
              field={f[:bio]}
              type="textarea"
              label="Bio"
              placeholder="Tell us about yourself, your skills, and what you're looking for..."
              rows="8"
              class="w-full"
              required
            />
            <p class="mt-2 text-sm text-base-content/60">
              Share your background, skills, interests, and what kind of projects you're looking for.
            </p>
          </div>

          <div>
            <label class="label">
              <span class="label-text">Technical Skills</span>
            </label>
            <p class="text-sm text-base-content/60 mb-4">
              Select the technologies and skills you're proficient in.
            </p>
            
    <!-- Hidden inputs for skills array -->
            <div style="display: none;">
              <%= for skill <- (Phoenix.HTML.Form.input_value(f, :skills) || []) do %>
                <input type="text" name="profile[skills][]" value={skill} />
              <% end %>
            </div>

            <div class="grid grid-cols-2 gap-4 mb-4">
              <div>
                <h4 class="text-sm font-medium mb-2">Frontend</h4>
                <.skills_input
                  field={f[:skills]}
                  available_tags={@technical_tags.frontend}
                  category="frontend"
                />
              </div>
              <div>
                <h4 class="text-sm font-medium mb-2">Backend</h4>
                <.skills_input
                  field={f[:skills]}
                  available_tags={@technical_tags.backend}
                  category="backend"
                />
              </div>
            </div>
            <div class="grid grid-cols-3 gap-4">
              <div>
                <h4 class="text-sm font-medium mb-2">Database</h4>
                <.skills_input
                  field={f[:skills]}
                  available_tags={@technical_tags.database}
                  category="database"
                />
              </div>
              <div>
                <h4 class="text-sm font-medium mb-2">DevOps</h4>
                <.skills_input
                  field={f[:skills]}
                  available_tags={@technical_tags.devops}
                  category="devops"
                />
              </div>
              <div>
                <h4 class="text-sm font-medium mb-2">Mobile</h4>
                <.skills_input
                  field={f[:skills]}
                  available_tags={@technical_tags.mobile}
                  category="mobile"
                />
              </div>
            </div>
          </div>

          <div>
            <label class="label">
              <span class="label-text">What I Can Offer</span>
            </label>
            <p class="text-sm text-base-content/60 mb-4">
              Select the services and expertise you can offer to projects.
            </p>
            
    <!-- Hidden inputs for offers array -->
            <div style="display: none;">
              <%= for offer <- (Phoenix.HTML.Form.input_value(f, :offers) || []) do %>
                <input type="text" name="profile[offers][]" value={offer} />
              <% end %>
            </div>

            <.offers_input field={f[:offers]} available_tags={@needs_tags} />
          </div>

          <div class="flex items-center justify-between pt-6 border-t">
            <.link navigate={~p"/users/settings"} class="btn btn-ghost">
              <.icon name="hero-arrow-left" class="size-4 mr-2" /> Back to Settings
            </.link>

            <.button type="submit" class="btn btn-primary" phx-disable-with="Saving...">
              <.icon name="hero-check" class="size-4 mr-2" /> Save Profile
            </.button>
          </div>
        </.form>

        <%= if @profile.bio && @profile.bio != "Tell us about yourself..." do %>
          <div class="mt-8 p-6 bg-base-200 rounded-lg">
            <h3 class="text-lg font-semibold mb-3">Preview</h3>
            <div class="prose prose-sm max-w-none">
              <p class="whitespace-pre-wrap">{@profile.bio}</p>
              <%= if @profile.skills && !Enum.empty?(@profile.skills) do %>
                <div class="mt-4">
                  <h4 class="text-sm font-medium mb-2">Technical Skills</h4>
                  <div class="flex flex-wrap gap-2">
                    <%= for skill <- @profile.skills do %>
                      <div class="badge badge-outline badge-secondary">{skill}</div>
                    <% end %>
                  </div>
                </div>
              <% end %>
              <%= if @profile.offers && !Enum.empty?(@profile.offers) do %>
                <div class="mt-4">
                  <h4 class="text-sm font-medium mb-2">What I Can Offer</h4>
                  <div class="flex flex-wrap gap-2">
                    <%= for offer <- @profile.offers do %>
                      <div class="badge badge-outline badge-accent">{offer}</div>
                    <% end %>
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

  attr :field, Phoenix.HTML.FormField
  attr :available_tags, :list
  attr :category, :string

  def skills_input(assigns) do
    # Get all current skills from the form
    all_skills =
      case Form.input_value(assigns.field.form, assigns.field.field) do
        nil -> []
        value when is_list(value) -> value
        _ -> []
      end

    # Filter the skills that belong to this category
    current_skills =
      filter_skills_by_category(all_skills, assigns.category, assigns.available_tags)

    assigns = assign(assigns, :current_skills, current_skills)
    assigns = assign(assigns, :category, assigns.category)

    ~H"""
    <div
      class="tag-input-container"
      id={"#{@field.name}-container-#{@category}"}
      phx-hook="tagAutocomplete"
    >
      <div class="selected-tags flex flex-wrap gap-2 mb-2">
        <%= for skill <- @current_skills do %>
          <div class="selected-tag bg-primary text-primary-content px-3 py-1 text-sm rounded-full flex items-center">
            <span>{skill}</span>
            <button
              type="button"
              phx-click="remove_tag"
              phx-value-tag={skill}
              phx-value-field={@field.name}
              phx-value-category={@category}
              class="ml-2 text-primary-content hover:text-white"
            >
              &times;
            </button>
          </div>
        <% end %>
      </div>
      <div class="relative">
        <input
          type="text"
          id={"#{@field.name}-#{@category}-tag-input"}
          phx-value-field={@field.name}
          phx-value-category={@category}
          placeholder="Type to add skills..."
          class="input input-bordered w-full"
          autocomplete="off"
        />
        <div
          id={"#{@field.name}-#{@category}-autocomplete"}
          class="autocomplete-suggestions hidden absolute z-10 w-full bg-base-100 mt-1 border border-base-300 rounded-md shadow-lg max-h-60 overflow-auto"
        >
          <%= for tag <- @available_tags do %>
            <div
              class="suggestion px-3 py-2 cursor-pointer hover:bg-base-200"
              phx-click="add_tag"
              phx-value-tag={tag}
              phx-value-field={@field.name}
              phx-value-category={@category}
            >
              {tag}
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  # Helper to filter skills by category
  defp filter_skills_by_category(all_skills, _category, available_tags) do
    # Only keep skills from the current category
    Enum.filter(all_skills, fn skill -> skill in available_tags end)
  end

  attr :field, Phoenix.HTML.FormField
  attr :available_tags, :list

  def offers_input(assigns) do
    # Get all current offers from the form
    all_offers =
      case Form.input_value(assigns.field.form, assigns.field.field) do
        nil -> []
        value when is_list(value) -> value
        _ -> []
      end

    assigns = assign(assigns, :current_offers, all_offers)

    ~H"""
    <div class="tag-input-container" id={"#{@field.name}-container-offers"} phx-hook="tagAutocomplete">
      <div class="selected-tags flex flex-wrap gap-2 mb-2">
        <%= for offer <- @current_offers do %>
          <div class="selected-tag bg-accent text-accent-content px-3 py-1 text-sm rounded-full flex items-center">
            <span>{offer}</span>
            <button
              type="button"
              phx-click="remove_tag"
              phx-value-tag={offer}
              phx-value-field={@field.name}
              phx-value-category="offers"
              class="ml-2 text-accent-content hover:text-white"
            >
              &times;
            </button>
          </div>
        <% end %>
      </div>
      <div class="relative">
        <input
          type="text"
          id={"#{@field.name}-offers-tag-input"}
          phx-value-field={@field.name}
          phx-value-category="offers"
          placeholder="Type to add what you can offer..."
          class="input input-bordered w-full"
          autocomplete="off"
        />
        <div
          id={"#{@field.name}-offers-autocomplete"}
          class="autocomplete-suggestions hidden absolute z-10 w-full bg-base-100 mt-1 border border-base-300 rounded-md shadow-lg max-h-60 overflow-auto"
        >
          <%= for tag <- @available_tags do %>
            <div
              class="suggestion px-3 py-2 cursor-pointer hover:bg-base-200"
              phx-click="add_tag"
              phx-value-tag={tag}
              phx-value-field={@field.name}
              phx-value-category="offers"
            >
              {tag}
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
