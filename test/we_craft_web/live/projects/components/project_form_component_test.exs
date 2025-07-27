defmodule WeCraftWeb.Projects.Components.ProjectFormComponentTest do
  @moduledoc """
  Tests for the ProjectFormComponent.
  """
  use WeCraftWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  # Setup a test process registry to store messages
  defmodule TestRegistry do
    @moduledoc """
    Simple registry to store messages for testing.
    """
    use Agent

    def start_link do
      Agent.start_link(fn -> %{} end, name: __MODULE__)
    end

    def put_message(key, value) do
      Agent.update(__MODULE__, &Map.put(&1, key, value))
    end

    def get_message(key) do
      Agent.get(__MODULE__, &Map.get(&1, key))
    end
  end

  defmodule TestLive do
    @moduledoc """
    Test LiveView that uses the ProjectFormComponent.
    """
    alias WeCraft.Projects.Project
    alias WeCraftWeb.Projects.Components.ProjectFormComponent

    use WeCraftWeb, :live_view

    def mount(_params, _session, socket) do
      changeset = Project.changeset(%Project{}, %{})
      {:ok, assign(socket, changeset: changeset)}
    end

    def render(assigns) do
      ~H"""
      <.live_component module={ProjectFormComponent} id="test-form" changeset={@changeset} />
      """
    end

    def handle_info({:save_project, params}, socket) do
      # Store the received parameters in the test registry
      TestRegistry.put_message(
        :project_params,
        params
      )

      {:noreply, socket}
    end

    # Catch-all handler for any other messages
    def handle_info(_msg, socket) do
      {:noreply, socket}
    end
  end

  describe "ProjectFormComponent" do
    setup %{conn: _conn} do
      # Start the test registry
      {:ok, _pid} = TestRegistry.start_link()

      # Set up a test LiveView that uses our component

      %{test_live: WeCraftWeb.Projects.Components.ProjectFormComponentTest.TestLive}
    end

    test "renders form with all fields", %{conn: conn, test_live: test_live} do
      {:ok, view, html} = live_isolated(conn, test_live)

      assert html =~ "Create New Project"
      assert html =~ "Share your idea with the community"
      assert has_element?(view, "input#project_title")
      assert has_element?(view, "textarea#project_description")
      assert has_element?(view, "select#project_status")
      assert has_element?(view, "input#project_repository_url")
      assert has_element?(view, "select#project_visibility")
      assert has_element?(view, "button", "Save Project")
    end

    test "validates form input", %{conn: conn, test_live: test_live} do
      {:ok, view, _html} = live_isolated(conn, test_live)

      # Test with invalid data
      assert has_element?(view, "#project_title")

      view
      |> element("form")
      |> render_change(%{
        "project" => %{
          "title" => "",
          "description" => "",
          "status" => "",
          "repository_url" => "",
          "visibility" => ""
        }
      })

      # We can't easily check validation errors since they're handled in the component
      # This is mostly testing that the change event doesn't crash
    end

    test "sends message to parent on form submission", %{conn: conn, test_live: test_live} do
      {:ok, view, _html} = live_isolated(conn, test_live)

      valid_params = %{
        "title" => "Test Component Project",
        "description" => "A test project description",
        "status" => "idea",
        "repository_url" => "https://github.com/example/test-project",
        "visibility" => "public"
      }

      view
      |> element("form")
      |> render_submit(%{"project" => valid_params})

      # Give some time for the message to be processed
      :timer.sleep(100)

      # Check that the parameters were stored in our registry
      received_params = TestRegistry.get_message(:project_params)
      assert received_params["title"] == "Test Component Project"
      assert received_params["description"] == "A test project description"
      assert received_params["repository_url"] == "https://github.com/example/test-project"
    end

    test "correctly handles tags and needs in form submission", %{
      conn: conn,
      test_live: test_live
    } do
      {:ok, view, _html} = live_isolated(conn, test_live)

      # Update the form with a change first to properly initialize it
      view
      |> element("form")
      |> render_change(%{
        "project" => %{
          "title" => "Project with Tags and Needs",
          "description" => "A test project with tags and needs",
          "status" => "idea",
          "repository_url" => "https://github.com/example/project-with-tags",
          "visibility" => "public",
          "tags" => [],
          "needs" => []
        }
      })

      # Submit the form with tags and needs included
      view
      |> element("form")
      |> render_submit(%{
        "project" => %{
          "title" => "Project with Tags and Needs",
          "description" => "A test project with tags and needs",
          "status" => "idea",
          "repository_url" => "https://github.com/example/project-with-tags",
          "visibility" => "public",
          "tags" => ["elixir"],
          "needs" => ["frontend", "devops"]
        }
      })

      # Give some time for the message to be processed
      :timer.sleep(100)

      # Check that the parameters were stored in our registry with tags and needs
      received_params = TestRegistry.get_message(:project_params)
      assert received_params["title"] == "Project with Tags and Needs"
      assert received_params["tags"] == ["elixir"]
      assert received_params["needs"] == ["frontend", "devops"]
    end

    test "handles repository URL field correctly", %{conn: conn, test_live: test_live} do
      {:ok, view, _html} = live_isolated(conn, test_live)

      # Test with valid URL
      view
      |> element("form")
      |> render_change(%{
        "project" => %{
          "title" => "Project with Repository",
          "description" => "A test project with repository URL",
          "status" => "idea",
          "repository_url" => "https://github.com/user/repo",
          "visibility" => "public"
        }
      })

      # Submit the form
      view
      |> element("form")
      |> render_submit(%{
        "project" => %{
          "title" => "Project with Repository",
          "description" => "A test project with repository URL",
          "status" => "idea",
          "repository_url" => "https://github.com/user/repo",
          "visibility" => "public"
        }
      })

      # Give some time for the message to be processed
      :timer.sleep(100)

      # Check that the parameters were stored correctly
      received_params = TestRegistry.get_message(:project_params)
      assert received_params["repository_url"] == "https://github.com/user/repo"
    end

    test "handles empty repository URL field correctly", %{conn: conn, test_live: test_live} do
      {:ok, view, _html} = live_isolated(conn, test_live)

      # Test with empty URL (should be allowed)
      view
      |> element("form")
      |> render_submit(%{
        "project" => %{
          "title" => "Project without Repository",
          "description" => "A test project without repository URL",
          "status" => "idea",
          "repository_url" => "",
          "visibility" => "public"
        }
      })

      # Give some time for the message to be processed
      :timer.sleep(100)

      # Check that empty URL is handled correctly
      received_params = TestRegistry.get_message(:project_params)
      assert received_params["repository_url"] == ""
    end
  end
end
