defmodule WeCraftWeb.Projects.Components.ProjectFormComponent do
  @moduledoc """
  Component for the project creation and editing form.
  """
  use WeCraftWeb, :live_component

  alias Phoenix.HTML.Form
  alias WeCraft.Projects.Project
  alias WeCraft.Projects.{BusinessTags, NeedsTags, TechnicalTags}
  alias WeCraftWeb.Components.TagInputComponent

  def update(%{action: :validate, project_params: project_params} = _assigns, socket) do
    changeset =
      %Project{}
      |> Project.changeset(project_params)
      |> Map.put(:action, :validate)

    {:ok, assign_form(socket, changeset)}
  end

  def update(%{action: :toggle_tag, params: params} = _assigns, socket) do
    {:ok, socket} = handle_event("toggle_tag", params, socket)
    {:ok, socket}
  end

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:technical_tags, TechnicalTags.all_tags_by_category())
     |> assign(:needs_tags, NeedsTags.all_needs())
     |> assign(:business_tags, BusinessTags.all_tags())
     |> assign_form(assigns.changeset)}
  end

  def handle_event("validate", %{"project" => project_params}, socket) do
    # Get the current form data and merge with new params
    current_form = socket.assigns.form

    # Filter out keys that start with "_unused_"
    filtered_params =
      project_params
      |> Enum.filter(fn {k, _v} -> not String.starts_with?(to_string(k), "_unused_") end)
      |> Map.new()

    # Convert all keys to atoms for Ecto
    atomized_params =
      for {key, val} <- filtered_params, into: %{} do
        {to_atom(key), val}
      end

    # Get existing form data - both changes and data
    current_data =
      Map.merge(
        Map.new(current_form.source.data |> Map.from_struct()),
        Map.new(current_form.source.changes)
      )

    # Special handling for tag-only updates
    is_tag_only_update =
      map_size(atomized_params) == 1 &&
        (Map.has_key?(atomized_params, :tags) || Map.has_key?(atomized_params, "tags") ||
           Map.has_key?(atomized_params, :needs) || Map.has_key?(atomized_params, "needs"))

    # Merge the params, preserving arrays like tags and needs
    # When updating only tags/needs, keep all other form values
    merged_params =
      if is_tag_only_update do
        # When updating only tags, keep all other form values
        Map.merge(current_data, atomized_params)
      else
        # Normal form update - replace values with new ones
        Map.merge(current_data, atomized_params)
      end

    changeset =
      %Project{}
      |> Project.changeset(merged_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"project" => project_params}, socket) do
    # Get the current form data and prepare final parameters
    final_params = prepare_save_params(project_params, socket.assigns.form)

    # Send the params to the parent LiveView
    send(self(), {:save_project, final_params})
    {:noreply, socket}
  end

  def handle_event("toggle_tag", %{"tag" => tag, "field" => field}, socket) do
    current_form = socket.assigns.form
    field_name = extract_field_name(field)
    current_field_value = Form.input_value(current_form, field_name) || []

    # Toggle the tag (remove if present, add if not)
    updated_value = toggle_tag_in_list(tag, current_field_value)

    # Create params map with the correct field name, ensuring string keys for consistency
    params = %{to_string(field_name) => updated_value}

    # Update the form with the new tag value
    handle_event("validate", %{"project" => params}, socket)
  end

  def handle_event("add_tag", %{"tag" => tag, "field" => field, "category" => category}, socket) do
    add_tag_to_field(tag, field, category, socket)
  end

  def handle_event(
        "remove_tag",
        %{"tag" => tag, "field" => field, "category" => _category},
        socket
      ) do
    current_form = socket.assigns.form
    field_name = extract_field_name(field)
    current_field_value = Form.input_value(current_form, field_name) || []

    # Remove the tag from the list
    updated_value = Enum.reject(current_field_value, &(&1 == tag))

    # Create params with string keys for consistency
    params = %{to_string(field_name) => updated_value}

    # Clear the tag filter and update the form
    socket = assign(socket, :tag_filter, "")
    handle_event("validate", %{"project" => params}, socket)
  end

  def handle_event(
        "handle_tag_input",
        %{"key" => key, "value" => input_value, "field" => field, "category" => category},
        socket
      )
      when key in ["Enter", "Tab"] do
    if input_value && input_value != "" do
      # Prevent default form submission on Enter key
      socket = add_tag_to_field(input_value, field, category, socket)
      {:noreply, assign(socket, :tag_filter, "")}
    else
      {:noreply, socket}
    end
  end

  def handle_event(
        "handle_tag_input",
        %{"value" => input_value, "field" => _field, "category" => _category},
        socket
      ) do
    {:noreply, assign(socket, :tag_filter, input_value)}
  end

  def handle_event("handle_tag_input", %{"value" => input_value}, socket) do
    {:noreply, assign(socket, :tag_filter, input_value)}
  end

  defp add_tag_to_field(tag, field, category, socket) do
    current_form = socket.assigns.form
    field_name = extract_field_name(field)
    current_field_value = Form.input_value(current_form, field_name) || []

    # Only add the tag if it's not already in the list
    if Enum.member?(current_field_value, tag) do
      socket
    else
      # Check if the tag is valid for the category (if applicable)
      if valid_tag_for_category?(tag, field_name, category, socket.assigns) do
        # Update the form with the new tag
        add_normalized_tag(tag, field_name, current_field_value, socket)
      else
        socket
      end
    end
  end

  # Extract field name from form field path (e.g., "project[tags]" -> :tags)
  defp extract_field_name(field) do
    field |> String.replace(~r/^project\[(.+)\]$/, "\\1") |> String.to_existing_atom()
  end

  # Check if tag is valid for the given category
  defp valid_tag_for_category?(tag, field_name, category, assigns) do
    # Check validation based on field type
    cond do
      # For technical tags field with category specified
      category && field_name == :tags ->
        all_tags_by_category = assigns.technical_tags
        category_atom = safe_string_to_atom(category)
        category_tags = Map.get(all_tags_by_category, category_atom, [])
        tag in category_tags

      # For business domains field
      field_name == :business_domains ->
        business_tags = assigns.business_tags
        tag in business_tags

      # For needs field
      field_name == :needs ->
        needs_tags = assigns.needs_tags
        tag in needs_tags

      # Default case - no validation
      true ->
        true
    end
  end

  # Safely convert string to atom
  defp safe_string_to_atom(string) do
    String.to_existing_atom(string)
  rescue
    ArgumentError -> String.to_atom(string)
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
    handle_event("validate", %{"project" => params}, socket)
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "project")
    assign(socket, form: form)
  end

  attr :field, Phoenix.HTML.FormField
  attr :available_tags, :list
  attr :category, :string
  attr :myself, :any

  def tags_input(assigns) do
    # Get all current tags from the form
    all_tags = Form.input_value(assigns.field.form, assigns.field.field) || []

    # Filter the tags that belong to this category
    current_tags = filter_tags_by_category(all_tags, assigns.category, assigns.available_tags)

    assigns = assign(assigns, :current_tags, current_tags)
    assigns = assign(assigns, :category, assigns.category)

    ~H"""
    <TagInputComponent.tag_input_autocomplete
      field={@field.name}
      available_tags={@available_tags}
      selected_tags={@current_tags}
      myself={@myself}
      category={@category}
    />
    """
  end

  # Helper to filter tags by category
  defp filter_tags_by_category(all_tags, _category, available_tags) do
    # Only keep tags from the current category
    Enum.filter(all_tags, fn tag -> tag in available_tags end)
  end

  attr :field, :any
  attr :available_tags, :list
  attr :myself, :any

  def needs_tags_input(assigns) do
    current_needs = Form.input_value(assigns.field.form, assigns.field.field) || []

    assigns = assign(assigns, :current_needs, current_needs)
    assigns = assign(assigns, :category, "needs")

    ~H"""
    <TagInputComponent.tag_input_autocomplete
      field={@field.name}
      available_tags={@available_tags}
      selected_tags={@current_needs}
      myself={@myself}
      category={@category}
    />
    """
  end

  def business_tags_input(assigns) do
    # Get current business domains or default to empty array
    current_business = Form.input_value(assigns.field.form, assigns.field.field) || []

    assigns = assign(assigns, :current_business, current_business)
    assigns = assign(assigns, :category, "business")

    ~H"""
    <TagInputComponent.tag_input_autocomplete
      field={@field.name}
      available_tags={@available_tags}
      selected_tags={@current_business}
      myself={@myself}
      category={@category}
    />
    """
  end

  # Helper for displaying form field errors
  attr :field, Phoenix.HTML.FormField

  def form_field_error(assigns) do
    ~H"""
    <%= if @field.errors != [] do %>
      <div class="text-error text-sm mt-1">
        {error_string(@field.errors)}
      </div>
    <% end %>
    """
  end

  # Helper to format error messages
  defp error_string(errors) do
    Enum.map_join(errors, ", ", fn {msg, _opts} -> msg end)
  end

  # Helper function to convert string keys to atoms safely
  defp to_atom(key) when is_atom(key), do: key

  defp to_atom(key) when is_binary(key) do
    String.to_existing_atom(key)
  rescue
    ArgumentError -> String.to_atom(key)
  end

  # Helper to toggle a tag in a list (add if not present, remove if present)
  defp toggle_tag_in_list(tag, tag_list) do
    if tag in tag_list do
      Enum.reject(tag_list, &(&1 == tag))
    else
      [tag | tag_list]
    end
  end

  # Extract a helper function to prepare parameters for saving
  defp prepare_save_params(project_params, form) do
    # Convert to string keys for consistency
    string_keyed_params =
      for {key, val} <- project_params, into: %{} do
        {to_string(key), val}
      end

    # Get current tags, needs, and business domains from the form or fallback to params
    current_tags = get_form_field_value(form, :tags, project_params["tags"] || [])
    current_needs = get_form_field_value(form, :needs, project_params["needs"] || [])

    current_business_domains =
      get_form_field_value(form, :business_domains, project_params["business_domains"] || [])

    # Build the final parameters with all needed fields
    string_keyed_params
    |> Map.put("tags", current_tags)
    |> Map.put("needs", current_needs)
    |> Map.put("business_domains", current_business_domains)
  end

  # Helper to get form field values with fallback
  defp get_form_field_value(form, field, fallback) do
    case Form.input_value(form, field) do
      nil -> fallback
      [] -> fallback
      value -> value
    end
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-3xl mx-auto bg-base-100 shadow-lg rounded-lg p-6">
      <.header>
        Create New Project
        <:subtitle>Share your idea with the community</:subtitle>
      </.header>

      <.form for={@form} phx-submit="save" phx-change="validate" phx-target={@myself}>
        <div class="space-y-4">
          <.input field={@form[:title]} type="text" label="Project Title" required />
          <.input field={@form[:description]} type="textarea" label="Description" required />

          <div class="form-control">
            <label class="label">
              <span class="label-text">Technical Stack</span>
            </label>
            <div class="grid grid-cols-2 gap-4 mb-4">
              <div>
                <h4 class="text-sm font-medium mb-2">Frontend</h4>
                <.tags_input
                  field={@form[:tags]}
                  available_tags={@technical_tags.frontend}
                  category="frontend"
                  myself={@myself}
                />
              </div>
              <div>
                <h4 class="text-sm font-medium mb-2">Backend</h4>
                <.tags_input
                  field={@form[:tags]}
                  available_tags={@technical_tags.backend}
                  category="backend"
                  myself={@myself}
                />
              </div>
            </div>
            <div class="grid grid-cols-3 gap-4">
              <div>
                <h4 class="text-sm font-medium mb-2">Database</h4>
                <.tags_input
                  field={@form[:tags]}
                  available_tags={@technical_tags.database}
                  category="database"
                  myself={@myself}
                />
              </div>
              <div>
                <h4 class="text-sm font-medium mb-2">DevOps</h4>
                <.tags_input
                  field={@form[:tags]}
                  available_tags={@technical_tags.devops}
                  category="devops"
                  myself={@myself}
                />
              </div>
              <div>
                <h4 class="text-sm font-medium mb-2">Mobile</h4>
                <.tags_input
                  field={@form[:tags]}
                  available_tags={@technical_tags.mobile}
                  category="mobile"
                  myself={@myself}
                />
              </div>
            </div>
            <.form_field_error field={@form[:tags]} />
          </div>

          <div class="form-control">
            <label class="label">
              <span class="label-text">What help do you need?</span>
            </label>
            <.needs_tags_input field={@form[:needs]} available_tags={@needs_tags} myself={@myself} />
            <.form_field_error field={@form[:needs]} />
          </div>

          <div class="form-control">
            <label class="label">
              <span class="label-text">What is business area?</span>
            </label>
            <.business_tags_input
              field={@form[:business_domains]}
              available_tags={@business_tags}
              myself={@myself}
            />
            <.form_field_error field={@form[:business_domains]} />
          </div>

          <.input
            field={@form[:status]}
            type="select"
            label="Project Status"
            options={Project.all_statuses() |> Enum.map(&{Project.status_display(&1), &1})}
            required
          />

          <.input field={@form[:repository_url]} type="url" label="Repository url" />

          <.input
            field={@form[:visibility]}
            type="select"
            label="Visibility"
            options={[{"Public", :public}]}
            required
          />

          <div class="mt-6">
            <.button type="submit" class="btn btn-primary w-full">Save Project</.button>
          </div>
        </div>
      </.form>
    </div>
    """
  end
end
