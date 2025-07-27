defmodule WeCraftWeb.Projects.Components.SearchFormComponent do
  @moduledoc """
  Component for the project search form.
  """
  use WeCraftWeb, :live_component

  alias WeCraft.Projects.TechnicalTags

  alias WeCraft.Projects.BusinessTags

  def mount(socket) do
    {:ok,
     assign(socket, :search_query, %{title: "", tags: [], business_domains: [], status: nil})}
  end

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:tag_filter, "")
     |> assign(:business_domain_filter, "")
     |> assign(:technical_tags, TechnicalTags.all_tags())
     |> assign(:business_domains, BusinessTags.all_tags())
     |> assign(:selected_business_domains, [])
     |> assign(:status_options, [
       %{label: "All Status", value: ""},
       %{label: "Idea", value: "idea"},
       %{label: "In Development", value: "in_dev"},
       %{label: "Private Beta", value: "private_beta"},
       %{label: "Public Beta", value: "public_beta"},
       %{label: "Live", value: "live"}
     ])}
  end

  def handle_event("search", %{"search" => search_params}, socket) do
    # Get the status value from parameters
    status_param = Map.get(search_params, "status", "")

    # Convert status to atom if it's not empty
    status =
      case status_param do
        "" -> nil
        value -> String.to_existing_atom(value)
      end

    # Extract search parameters and create a clean search query
    search_query = %{
      title: Map.get(search_params, "title", ""),
      tags: Map.get(socket.assigns, :selected_tags, []),
      business_domains: Map.get(socket.assigns, :selected_business_domains, []),
      status: status
    }

    # Notify parent to perform the search
    send(self(), {:search_projects, search_query})

    {:noreply, assign(socket, :search_query, search_query)}
  end

  def handle_event("add_tag", %{"tag" => tag}, socket) do
    selected_tags = socket.assigns[:selected_tags] || []

    # Only add tag if not already present
    updated_tags =
      if tag in selected_tags do
        selected_tags
      else
        [tag | selected_tags]
      end

    {:noreply, assign(socket, :selected_tags, updated_tags)}
  end

  def handle_event("remove_tag", %{"tag" => tag}, socket) do
    selected_tags = socket.assigns[:selected_tags] || []
    updated_tags = Enum.reject(selected_tags, &(&1 == tag))

    {:noreply, assign(socket, :selected_tags, updated_tags)}
  end

  def handle_event("handle_tag_input", %{"value" => value, "category" => "business"}, socket) do
    {:noreply, assign(socket, :business_domain_filter, value)}
  end

  def handle_event("handle_tag_input", %{"value" => value}, socket) do
    {:noreply, assign(socket, :tag_filter, value)}
  end

  def handle_event("add_business_domain", %{"domain" => domain}, socket) do
    selected_domains = socket.assigns[:selected_business_domains] || []

    # Only add domain if not already present
    updated_domains =
      if domain in selected_domains do
        selected_domains
      else
        [domain | selected_domains]
      end

    {:noreply, assign(socket, :selected_business_domains, updated_domains)}
  end

  def handle_event("remove_business_domain", %{"domain" => domain}, socket) do
    selected_domains = socket.assigns[:selected_business_domains] || []
    updated_domains = Enum.reject(selected_domains, &(&1 == domain))

    {:noreply, assign(socket, :selected_business_domains, updated_domains)}
  end

  def render(assigns) do
    ~H"""
    <div class="project-search-form mb-8">
      <.form
        for={%{}}
        as={:search}
        phx-submit="search"
        phx-target={@myself}
        class="bg-base-100 border border-base-300 rounded-lg shadow-sm p-4"
      >
        <!-- Top row: Title and Status -->
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-4 mb-4">
          <div class="form-control lg:col-span-2">
            <label class="label">
              <span class="label-text font-medium">Project Title</span>
            </label>
            <input
              type="text"
              name="search[title]"
              placeholder="Search by title..."
              class="input input-bordered w-full"
              value={@search_query.title}
            />
          </div>

          <div class="form-control">
            <label class="label">
              <span class="label-text font-medium">Status</span>
            </label>
            <select name="search[status]" class="select select-bordered w-full">
              <%= for option <- @status_options do %>
                <option
                  value={option.value}
                  selected={selected_status?(@search_query.status, option.value)}
                >
                  {option.label}
                </option>
              <% end %>
            </select>
          </div>
        </div>
        
    <!-- Bottom row: Tags and Business Domains -->
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-4 mb-4">
          <div class="form-control">
            <label class="label">
              <span class="label-text font-medium">Tech Stack</span>
            </label>
            <div
              class="tag-input-container"
              id="search-tags-container"
              phx-hook="tagAutocomplete"
              phx-target={@myself}
            >
              <%= if length(@selected_tags || []) > 0 do %>
                <div class="selected-tags flex flex-wrap gap-1 mb-2">
                  <%= for tag <- @selected_tags || [] do %>
                    <div class="selected-tag bg-primary text-primary-content px-2 py-1 text-xs rounded-full flex items-center">
                      <span>{tag}</span>
                      <button
                        type="button"
                        phx-click="remove_tag"
                        phx-value-tag={tag}
                        phx-target={@myself}
                        class="ml-1 text-primary-content hover:text-white text-sm"
                      >
                        &times;
                      </button>
                    </div>
                  <% end %>
                </div>
              <% end %>
              <div class="relative">
                <input
                  type="text"
                  id="search-tags-tag-input"
                  phx-value-field="search[tags]"
                  phx-value-category="search"
                  placeholder="Add tech tags..."
                  class="input input-bordered input-sm w-full"
                  autocomplete="off"
                />
                <div
                  id="search-tags-autocomplete"
                  class="autocomplete-suggestions hidden absolute z-10 w-full bg-base-100 mt-1 border border-base-300 rounded-md shadow-lg max-h-48 overflow-auto"
                >
                  <%= for tag <- filter_tags(@technical_tags, @tag_filter) do %>
                    <div
                      class="suggestion px-3 py-2 cursor-pointer hover:bg-base-200 text-sm"
                      phx-click="add_tag"
                      phx-value-tag={tag}
                      phx-target={@myself}
                    >
                      {tag}
                    </div>
                  <% end %>
                </div>
              </div>
            </div>
          </div>

          <div class="form-control">
            <label class="label">
              <span class="label-text font-medium">Business Domain</span>
            </label>
            <div
              class="tag-input-container"
              id="search-business-domains-container"
              phx-hook="tagAutocomplete"
              phx-target={@myself}
            >
              <%= if length(@selected_business_domains || []) > 0 do %>
                <div class="selected-tags flex flex-wrap gap-1 mb-2">
                  <%= for domain <- @selected_business_domains || [] do %>
                    <div class="selected-tag bg-secondary text-secondary-content px-2 py-1 text-xs rounded-full flex items-center">
                      <span>{domain}</span>
                      <button
                        type="button"
                        phx-click="remove_business_domain"
                        phx-value-domain={domain}
                        phx-target={@myself}
                        class="ml-1 text-secondary-content hover:text-white text-sm"
                      >
                        &times;
                      </button>
                    </div>
                  <% end %>
                </div>
              <% end %>
              <div class="relative">
                <input
                  type="text"
                  id="search-business-domains-tag-input"
                  phx-value-field="search[business_domains]"
                  phx-value-category="business"
                  placeholder="Add business domains..."
                  class="input input-bordered input-sm w-full"
                  autocomplete="off"
                />
                <div
                  id="search-business-domains-autocomplete"
                  class="autocomplete-suggestions hidden absolute z-10 w-full bg-base-100 mt-1 border border-base-300 rounded-md shadow-lg max-h-48 overflow-auto"
                >
                  <%= for domain <- filter_tags(@business_domains, @business_domain_filter) do %>
                    <div
                      class="suggestion px-3 py-2 cursor-pointer hover:bg-base-200 text-sm"
                      phx-click="add_business_domain"
                      phx-value-domain={domain}
                      phx-target={@myself}
                    >
                      {domain}
                    </div>
                  <% end %>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="flex justify-center">
          <button type="submit" class="btn btn-primary btn-sm px-8">
            <.icon name="hero-magnifying-glass" class="h-4 w-4 mr-2" /> Search Projects
          </button>
        </div>
      </.form>
    </div>
    """
  end

  # Helper function to filter tags based on input
  def filter_tags(tags, filter) when is_binary(filter) and filter != "" do
    filter_downcased = String.downcase(filter)

    Enum.filter(tags, fn tag ->
      String.downcase(tag) =~ filter_downcased
    end)
  end

  def filter_tags(tags, _), do: tags

  # Helper function to compare status values correctly
  def selected_status?(nil, ""), do: true
  def selected_status?(status, value) when is_atom(status), do: Atom.to_string(status) == value
  def selected_status?(_, _), do: false
end
