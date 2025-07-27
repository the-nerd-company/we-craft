defmodule WeCraftWeb.Projects.ChatComponentTest do
  @moduledoc """
  Tests for the WeCraftWeb.Projects.ChatComponent module.
  """
  use WeCraftWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import WeCraft.AccountsFixtures

  alias WeCraft.ProjectsFixtures
  alias WeCraftWeb.Projects.ChatComponent

  defmodule TestLiveView do
    @moduledoc """
    A simple LiveView to test the ChatComponent.
    """
    use WeCraftWeb, :live_view

    alias WeCraftWeb.Projects.ChatComponent

    def mount(_params, session, socket) do
      socket =
        socket
        |> Phoenix.Component.assign(:id, session["id"])
        |> Phoenix.Component.assign(:chat, session["chat"])
        |> Phoenix.Component.assign(:current_user, session["current_user"])

      {:ok, socket}
    end

    def render(assigns) do
      ~H"""
      <.live_component module={ChatComponent} id={@id} chat={@chat} current_user={@current_user} />
      """
    end
  end

  setup do
    %{confirmed_user: user_fixture()}
  end

  describe "live component integration" do
    test "initializes with sorted messages and current_user_id", %{
      conn: conn,
      confirmed_user: confirmed_user
    } do
      project = ProjectsFixtures.project_fixture(%{owner: confirmed_user})

      chat = %{
        id: project.id,
        is_main: true,
        name: nil,
        description: nil,
        messages: [
          %{
            id: 2,
            content: "Hello!",
            sender_id: confirmed_user.id,
            sender: confirmed_user,
            timestamp: ~N[2023-01-01 10:00:00]
          },
          %{
            id: 1,
            content: "Hello!",
            sender_id: confirmed_user.id,
            sender: confirmed_user,
            timestamp: ~N[2023-01-01 09:00:00]
          }
        ]
      }

      params = %{"id" => chat.id, "chat" => chat, "current_user" => confirmed_user}
      {:ok, lv, _html} = live_isolated(conn, TestLiveView, session: params)

      assigns = :sys.get_state(lv.pid).socket.assigns
      assert assigns.chat.messages == chat.messages
      assert assigns.current_user.id == confirmed_user.id
    end
  end
end
