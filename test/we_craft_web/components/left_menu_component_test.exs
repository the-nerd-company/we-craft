defmodule WeCraftWeb.Components.LeftMenuComponentTest do
  @moduledoc false
  use WeCraftWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import WeCraft.ProjectsFixtures
  import WeCraft.AccountsFixtures, only: [user_scope_fixture: 0]
  import WeCraft.MilestonesFixtures
  import WeCraft.ChatsFixtures
  import WeCraft.PagesFixtures

  alias WeCraftWeb.Components.LeftMenu

  defmodule HarnessLive do
    @moduledoc false
    use WeCraftWeb, :live_view
    alias Phoenix.Component, as: PC

    def mount(_params, session, socket) do
      {:ok,
       socket
       |> PC.assign(:project, session["project"])
       |> PC.assign(:current_scope, session["current_scope"])
       |> PC.assign(:chats, session["chats"] || [])
       |> PC.assign(:active_milestones, session["active_milestones"] || [])
       |> PC.assign(:pages, session["pages"] || [])
       |> PC.assign(:current_section, session["current_section"] || :chat)
       |> PC.assign(:current_chat, nil)
       |> PC.assign(:current_page_id, session["current_page_id"])}
    end

    def render(assigns) do
      ~H"""
      <.live_component
        module={LeftMenu}
        id="lm"
        project={@project}
        current_scope={@current_scope}
        chats={@chats}
        active_milestones={@active_milestones}
        pages={@pages}
        current_section={@current_section}
        current_chat={@current_chat}
        current_page_id={@current_page_id}
      />
      """
    end
  end

  test "renders with project info and collapsible sections" do
    scope = user_scope_fixture()
    project = project_fixture()
    chat = chat_fixture(%{project: project})
    milestone = milestone_fixture(%{project: project, status: :active})
    page = page_fixture(%{project: project})

    {:ok, view, _} =
      live_isolated(build_conn(), HarnessLive,
        session: %{
          "current_scope" => scope,
          "project" => project,
          "chats" => [chat],
          "active_milestones" => [milestone],
          "pages" => [page],
          "current_section" => :chat
        }
      )

    html = render(view)
    assert html =~ project.title
    assert html =~ "Channels"
    assert html =~ milestone.title
    assert html =~ page.title

    render_click(element(view, "button[phx-value-section=chats]"))
    render_click(element(view, "button[phx-value-section=pages]"))
  end

  test "select chat sends events" do
    scope = user_scope_fixture()
    project = project_fixture()
    chat = chat_fixture(%{project: project})

    {:ok, view, _} =
      live_isolated(build_conn(), HarnessLive,
        session: %{"current_scope" => scope, "project" => project, "chats" => [chat]}
      )

    render_click(element(view, "button[phx-value-chat-id='#{chat.id}']"))
  end

  test "select page navigates" do
    scope = user_scope_fixture()
    project = project_fixture()
    page = page_fixture(%{project: project})

    {:ok, view, _} =
      live_isolated(build_conn(), HarnessLive,
        session: %{"current_scope" => scope, "project" => project, "pages" => [page]}
      )

    render_click(element(view, "button[phx-value-page-id='#{page.id}']"))
  end
end
