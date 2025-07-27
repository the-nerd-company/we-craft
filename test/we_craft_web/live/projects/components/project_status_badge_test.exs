defmodule WeCraftWeb.Projects.Components.ProjectStatusBadgeTest do
  @moduledoc """
  Tests for the ProjectStatusBadge component.
  """
  use WeCraftWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Phoenix.Component

  alias WeCraftWeb.Projects.Components.ProjectStatusBadge

  defmodule TestLiveView do
    @moduledoc """
    A simple LiveView to test the ProjectStatusBadge component.
    """
    use WeCraftWeb, :live_view

    def mount(_params, session, socket) do
      socket = Phoenix.Component.assign(socket, :project, session["project"])
      {:ok, socket}
    end

    def render(assigns) do
      ~H"""
      <ProjectStatusBadge.project_status_badge project={@project} />
      """
    end
  end

  describe "project_status_badge/1" do
    test "renders badge for :idea status", %{conn: conn} do
      project = %{status: :idea}
      params = %{"project" => project}

      {:ok, _lv, html} = live_isolated(conn, TestLiveView, session: params)

      assert html =~ "badge badge-primary badge-info"
      assert html =~ "Idea"
    end

    test "renders badge for :in_dev status", %{conn: conn} do
      project = %{status: :in_dev}
      params = %{"project" => project}

      {:ok, _lv, html} = live_isolated(conn, TestLiveView, session: params)

      assert html =~ "badge badge-primary badge-warning"
      assert html =~ "In Dev"
    end

    test "renders badge for :private_beta status", %{conn: conn} do
      project = %{status: :private_beta}
      params = %{"project" => project}

      {:ok, _lv, html} = live_isolated(conn, TestLiveView, session: params)

      assert html =~ "badge badge-primary badge-secondary"
      assert html =~ "Private β"
    end

    test "renders badge for :public_beta status", %{conn: conn} do
      project = %{status: :public_beta}
      params = %{"project" => project}

      {:ok, _lv, html} = live_isolated(conn, TestLiveView, session: params)

      assert html =~ "badge badge-primary badge-accent"
      assert html =~ "Public β"
    end

    test "renders badge for :live status", %{conn: conn} do
      project = %{status: :live}
      params = %{"project" => project}

      {:ok, _lv, html} = live_isolated(conn, TestLiveView, session: params)

      assert html =~ "badge badge-primary badge-success"
      assert html =~ "Live"
    end

    test "renders badge with neutral class for unknown status atom", %{conn: conn} do
      project = %{status: :unknown_status}
      params = %{"project" => project}

      {:ok, _lv, html} = live_isolated(conn, TestLiveView, session: params)

      assert html =~ "badge badge-primary badge-neutral"
      assert html =~ "Unknown_status"
    end

    test "renders badge with neutral class for string status", %{conn: conn} do
      project = %{status: "custom_status"}
      params = %{"project" => project}

      {:ok, _lv, html} = live_isolated(conn, TestLiveView, session: params)

      assert html =~ "badge badge-primary badge-neutral"
      assert html =~ "custom_status"
    end

    test "renders badge with neutral class for nil status", %{conn: conn} do
      project = %{status: nil}
      params = %{"project" => project}

      {:ok, _lv, html} = live_isolated(conn, TestLiveView, session: params)

      assert html =~ "badge badge-primary badge-neutral"
    end

    test "renders proper HTML structure", %{conn: conn} do
      project = %{status: :idea}
      params = %{"project" => project}

      {:ok, _lv, html} = live_isolated(conn, TestLiveView, session: params)

      # Check that it renders as a span with the correct classes
      assert html =~ ~r/<span class="badge badge-primary badge-info">/
      assert html =~ "Idea"
      assert html =~ "</span>"
    end

    test "handles all valid project status values", %{conn: conn} do
      valid_statuses = [:idea, :in_dev, :private_beta, :public_beta, :live]

      expected_classes = [
        "badge-info",
        "badge-warning",
        "badge-secondary",
        "badge-accent",
        "badge-success"
      ]

      expected_texts = ["Idea", "In Dev", "Private β", "Public β", "Live"]

      Enum.zip([valid_statuses, expected_classes, expected_texts])
      |> Enum.each(fn {status, expected_class, expected_text} ->
        project = %{status: status}
        params = %{"project" => project}

        {:ok, _lv, html} = live_isolated(conn, TestLiveView, session: params)

        assert html =~ expected_class
        assert html =~ expected_text
      end)
    end
  end

  describe "project_status_badge_xs/1" do
    defmodule TestLiveViewXS do
      @moduledoc """
      A simple LiveView to test the ProjectStatusBadge XS component.
      """
      use WeCraftWeb, :live_view

      def mount(_params, session, socket) do
        socket = Phoenix.Component.assign(socket, :project, session["project"])
        {:ok, socket}
      end

      def render(assigns) do
        ~H"""
        <ProjectStatusBadge.project_status_badge_xs project={@project} />
        """
      end
    end

    test "renders XS badge for :idea status", %{conn: conn} do
      project = %{status: :idea}
      params = %{"project" => project}

      {:ok, _lv, html} = live_isolated(conn, TestLiveViewXS, session: params)

      assert html =~ "badge badge-xs badge-info"
      assert html =~ "Idea"
    end

    test "renders XS badge for :in_dev status", %{conn: conn} do
      project = %{status: :in_dev}
      params = %{"project" => project}

      {:ok, _lv, html} = live_isolated(conn, TestLiveViewXS, session: params)

      assert html =~ "badge badge-xs badge-warning"
      assert html =~ "In Dev"
    end

    test "renders XS badge for :private_beta status", %{conn: conn} do
      project = %{status: :private_beta}
      params = %{"project" => project}

      {:ok, _lv, html} = live_isolated(conn, TestLiveViewXS, session: params)

      assert html =~ "badge badge-xs badge-secondary"
      assert html =~ "Private β"
    end

    test "renders XS badge for :public_beta status", %{conn: conn} do
      project = %{status: :public_beta}
      params = %{"project" => project}

      {:ok, _lv, html} = live_isolated(conn, TestLiveViewXS, session: params)

      assert html =~ "badge badge-xs badge-accent"
      assert html =~ "Public β"
    end

    test "renders XS badge for :live status", %{conn: conn} do
      project = %{status: :live}
      params = %{"project" => project}

      {:ok, _lv, html} = live_isolated(conn, TestLiveViewXS, session: params)

      assert html =~ "badge badge-xs badge-success"
      assert html =~ "Live"
    end

    test "renders XS badge with neutral class for unknown status", %{conn: conn} do
      project = %{status: :unknown_status}
      params = %{"project" => project}

      {:ok, _lv, html} = live_isolated(conn, TestLiveViewXS, session: params)

      assert html =~ "badge badge-xs badge-neutral"
      assert html =~ "Unknown_status"
    end

    test "renders proper XS HTML structure", %{conn: conn} do
      project = %{status: :idea}
      params = %{"project" => project}

      {:ok, _lv, html} = live_isolated(conn, TestLiveViewXS, session: params)

      # Check that it renders as a span with the correct XS classes
      assert html =~ ~r/<span class="badge badge-xs badge-info">/
      assert html =~ "Idea"
      assert html =~ "</span>"
    end

    test "handles all valid project status values for XS variant", %{conn: conn} do
      valid_statuses = [:idea, :in_dev, :private_beta, :public_beta, :live]

      expected_classes = [
        "badge-info",
        "badge-warning",
        "badge-secondary",
        "badge-accent",
        "badge-success"
      ]

      expected_texts = ["Idea", "In Dev", "Private β", "Public β", "Live"]

      Enum.zip([valid_statuses, expected_classes, expected_texts])
      |> Enum.each(fn {status, expected_class, expected_text} ->
        project = %{status: status}
        params = %{"project" => project}

        {:ok, _lv, html} = live_isolated(conn, TestLiveViewXS, session: params)

        assert html =~ "badge badge-xs #{expected_class}"
        assert html =~ expected_text
      end)
    end
  end
end
