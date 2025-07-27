defmodule WeCraftWeb.Components.TagInputComponent do
  @moduledoc """
  Reusable component for tag input with autocomplete functionality.
  """
  use WeCraftWeb, :html

  @doc """
  Renders a tag input field with autocomplete suggestions.

  ## Examples

      <.tag_input_autocomplete
        field="project[tags]"
        available_tags={@technical_tags.frontend}
        selected_tags={@current_tags}
        myself={@myself}
        category="frontend"
        on_change="tag_changed"
      />

  ## Attributes

  * `field` - The form field name
  * `available_tags` - List of available tags to suggest
  * `selected_tags` - List of currently selected tags
  * `category` - Optional category for tag filtering
  * `myself` - The LiveComponent that will handle the events
  * `placeholder` - Optional placeholder text for the input
  * `on_change` - Optional event name to trigger when tags change
  """
  attr :field, :string, required: true
  attr :available_tags, :list, required: true
  attr :selected_tags, :list, default: []
  attr :category, :string, default: nil
  attr :myself, :any
  attr :placeholder, :string, default: "Type to add tags..."
  attr :on_change, :string, default: nil

  def tag_input_autocomplete(assigns) do
    ~H"""
    <div
      class="tag-input-container"
      id={"#{@field}-container-#{@category}"}
      phx-hook="tagAutocomplete"
      phx-target={@myself}
    >
      <div class="selected-tags flex flex-wrap gap-2 mb-2">
        <%= for tag <- @selected_tags do %>
          <div class="selected-tag bg-primary text-primary-content px-3 py-1 text-sm rounded-full flex items-center">
            <span>{tag}</span>
            <button
              type="button"
              phx-click={@on_change || "remove_tag"}
              phx-value-tag={tag}
              phx-value-field={@field}
              phx-value-category={@category}
              phx-target={@myself}
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
          id={"#{@field}-#{@category}-tag-input"}
          phx-value-field={@field}
          phx-value-category={@category}
          placeholder={@placeholder}
          class="input input-bordered w-full"
          autocomplete="off"
        />
        <div
          id={"#{@field}-#{@category}-autocomplete"}
          class="autocomplete-suggestions hidden absolute z-10 w-full bg-base-100 mt-1 border border-base-300 rounded-md shadow-lg max-h-60 overflow-auto"
        >
          <%= for tag <- get_filtered_suggestions(@available_tags, assigns[:tag_filter] || "") do %>
            <div
              class="suggestion px-3 py-2 cursor-pointer hover:bg-base-200"
              phx-click={@on_change || "add_tag"}
              phx-value-tag={tag}
              phx-value-field={@field}
              phx-value-category={@category}
              phx-target={@myself}
            >
              {tag}
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  # Helper function to filter tag suggestions based on user input
  defp get_filtered_suggestions(available_tags, filter) when is_binary(filter) and filter != "" do
    filter_downcased = String.downcase(filter)

    Enum.filter(available_tags, fn tag ->
      String.downcase(tag) =~ filter_downcased
    end)
  end

  defp get_filtered_suggestions(available_tags, _), do: available_tags
end
