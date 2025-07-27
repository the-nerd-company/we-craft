defmodule WeCraftWeb.Components.TagInputComponentTest do
  @moduledoc """
  Tests for the TagInputComponent.
  """
  use ExUnit.Case, async: true
  use Phoenix.Component

  import Phoenix.LiveViewTest
  import WeCraftWeb.Components.TagInputComponent

  describe "tag_input_autocomplete/1" do
    test "renders input field with empty selected tags" do
      assigns = %{
        field: "project[tags]",
        available_tags: ["elixir", "phoenix", "react"],
        selected_tags: [],
        category: "frontend",
        myself: %Phoenix.LiveComponent.CID{cid: 1},
        placeholder: "Add tags...",
        on_change: nil
      }

      html =
        rendered_to_string(~H"""
        <.tag_input_autocomplete
          field={@field}
          available_tags={@available_tags}
          selected_tags={@selected_tags}
          category={@category}
          myself={@myself}
          placeholder={@placeholder}
          on_change={@on_change}
        />
        """)

      # Container should exist with correct ID and hook
      assert html =~ ~s(id="project[tags]-container-frontend")
      assert html =~ ~s(phx-hook="tagAutocomplete")

      # Input should exist with correct ID and placeholder
      assert html =~ ~s(id="project[tags]-frontend-tag-input")
      assert html =~ ~s(placeholder="Add tags...")

      # No selected tags should be displayed (check for no span elements in the selected-tags div)
      refute html =~ ~s(<span>elixir</span>)
      refute html =~ ~s(<span>phoenix</span>)
      refute html =~ ~s(<span>react</span>)

      # Suggestions container should exist
      assert html =~ ~s(id="project[tags]-frontend-autocomplete")

      # All available tags should be in suggestions
      assert html =~ "elixir"
      assert html =~ "phoenix"
      assert html =~ "react"
    end

    test "renders input with selected tags" do
      assigns = %{
        field: "project[tags]",
        available_tags: ["elixir", "phoenix", "react", "javascript"],
        selected_tags: ["elixir", "phoenix"],
        category: "backend",
        myself: %Phoenix.LiveComponent.CID{cid: 1},
        placeholder: "Type to add tags...",
        on_change: nil
      }

      html =
        rendered_to_string(~H"""
        <.tag_input_autocomplete
          field={@field}
          available_tags={@available_tags}
          selected_tags={@selected_tags}
          category={@category}
          myself={@myself}
          placeholder={@placeholder}
          on_change={@on_change}
        />
        """)

      # Selected tags should be rendered
      assert html =~ ~s(<span>elixir</span>)
      assert html =~ ~s(<span>phoenix</span>)
      refute html =~ ~s(<span>react</span>)

      # Each selected tag should have a remove button
      assert html =~ ~s(phx-click="remove_tag")
      assert html =~ ~s(phx-value-tag="elixir")
      assert html =~ ~s(phx-value-tag="phoenix")
    end

    test "uses custom on_change event handler when provided" do
      assigns = %{
        field: "project[tags]",
        available_tags: ["elixir", "phoenix"],
        selected_tags: ["elixir"],
        category: "backend",
        myself: %Phoenix.LiveComponent.CID{cid: 1},
        placeholder: "Type to add tags...",
        on_change: "custom_tag_action"
      }

      html =
        rendered_to_string(~H"""
        <.tag_input_autocomplete
          field={@field}
          available_tags={@available_tags}
          selected_tags={@selected_tags}
          category={@category}
          myself={@myself}
          placeholder={@placeholder}
          on_change={@on_change}
        />
        """)

      # Should use custom event handler
      assert html =~ ~s(phx-click="custom_tag_action")

      # For suggestions too
      assert html =~ ~s(class="suggestion px-3 py-2 cursor-pointer hover:bg-base-200")
      assert html =~ ~s(phx-click="custom_tag_action")
    end
  end

  describe "component UI features" do
    test "displays all required UI elements with correct attributes" do
      assigns = %{
        field: "project[needs]",
        available_tags: ["frontend", "backend", "design"],
        selected_tags: ["design"],
        category: "needs",
        myself: %Phoenix.LiveComponent.CID{cid: 1},
        placeholder: "Select needs..."
      }

      html =
        rendered_to_string(~H"""
        <.tag_input_autocomplete
          field={@field}
          available_tags={@available_tags}
          selected_tags={@selected_tags}
          category={@category}
          myself={@myself}
          placeholder={@placeholder}
        />
        """)

      # Check container attributes
      assert html =~ ~s(id="project[needs]-container-needs")
      assert html =~ ~s(phx-hook="tagAutocomplete")

      # Check input field attributes
      assert html =~ ~s(id="project[needs]-needs-tag-input")
      assert html =~ ~s(placeholder="Select needs...")
      assert html =~ ~s(phx-value-field="project[needs]")
      assert html =~ ~s(phx-value-category="needs")

      # Check suggestions container
      assert html =~ ~s(id="project[needs]-needs-autocomplete")
      assert html =~ ~s(class="autocomplete-suggestions hidden)
    end
  end
end
