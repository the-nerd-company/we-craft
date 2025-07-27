defmodule WeCraftWeb.Components.ProjectCardTest do
  @moduledoc """
  Tests for the WeCraftWeb.Components.ProjectCard module.
  """
  use WeCraftWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Phoenix.Component

  alias WeCraftWeb.Components.ProjectCard

  defmodule TestLiveView do
    @moduledoc """
    A simple LiveView to test the ProjectCard component.
    """
    use WeCraftWeb, :live_view

    alias WeCraftWeb.Components.ProjectCard

    def mount(_params, session, socket) do
      socket =
        socket
        |> Phoenix.Component.assign(:project, session["project"])

      {:ok, socket}
    end

    def render(assigns) do
      ~H"""
      <ProjectCard.liquid_glass_card project={@project} />
      """
    end
  end

  describe "liquid_glass_card/1" do
    test "renders project title and description", %{conn: conn} do
      project = %{
        title: "Test Project",
        description: "A test project description",
        status: nil,
        tags: [],
        business_domains: []
      }

      params = %{"project" => project}
      {:ok, _lv, html} = live_isolated(conn, TestLiveView, session: params)

      assert html =~ "Test Project"
      assert html =~ "A test project description"
      assert html =~ "View"
    end

    test "renders project with status badge", %{conn: conn} do
      project = %{
        title: "Test Project",
        description: "A test project description",
        status: :in_dev,
        tags: [],
        business_domains: []
      }

      params = %{"project" => project}
      {:ok, _lv, html} = live_isolated(conn, TestLiveView, session: params)

      assert html =~ "Test Project"
      assert html =~ "A test project description"
      assert html =~ "In Dev"
      assert html =~ "badge badge-xs badge-warning"
    end

    test "renders with the correct CSS classes for styling", %{conn: conn} do
      project = %{
        title: "Test Project",
        description: "A test project description",
        status: nil,
        tags: [],
        business_domains: []
      }

      params = %{"project" => project}
      {:ok, _lv, html} = live_isolated(conn, TestLiveView, session: params)

      assert html =~ "project-card"
      assert html =~ "shadow-md"
      assert html =~ "rounded-lg"
      assert html =~ "btn btn-xs btn-primary"
    end

    test "renders project tags when provided", %{conn: conn} do
      project = %{
        title: "Test Project",
        description: "A test project description",
        status: :live,
        tags: ["elixir", "phoenix", "liveview"],
        business_domains: ["fintech"]
      }

      params = %{"project" => project}
      {:ok, _lv, html} = live_isolated(conn, TestLiveView, session: params)

      assert html =~ "elixir"
      assert html =~ "phoenix"
      assert html =~ "liveview"
      assert html =~ "fintech"
      assert html =~ "Live"
    end

    test "limits displayed tags to 3 and shows overflow count", %{conn: conn} do
      project = %{
        title: "Test Project",
        description: "A test project description",
        status: nil,
        tags: ["elixir", "phoenix", "liveview", "postgresql", "tailwind"],
        business_domains: []
      }

      params = %{"project" => project}
      {:ok, _lv, html} = live_isolated(conn, TestLiveView, session: params)

      assert html =~ "elixir"
      assert html =~ "phoenix"
      assert html =~ "liveview"
      assert html =~ "+2"
      refute html =~ "postgresql"
      refute html =~ "tailwind"
    end
  end
end
