defmodule WeCraftWeb.Components.RichMessageTest do
  @moduledoc """
  Tests for RichMessage component functionality.
  """
  use WeCraftWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import WeCraft.ChatsFixtures
  import WeCraft.AccountsFixtures

  alias WeCraftWeb.Components.RichMessage

  defmodule TestLiveView do
    @moduledoc """
    A simple LiveView to test the RichMessage component.
    """
    use WeCraftWeb, :live_view

    def mount(_params, session, socket) do
      # Convert string keys to atom keys for assigns
      assigns = %{
        message: session["message"],
        current_user: session["current_user"]
      }

      socket = assign(socket, assigns)
      {:ok, socket}
    end

    def render(assigns) do
      ~H"""
      <.live_component
        module={RichMessage}
        id="rich-message-test"
        message={@message}
        current_user={@current_user}
        chat_target="chat-component"
      />
      """
    end
  end

  describe "render/1" do
    test "renders simple text message without rich content", %{conn: conn} do
      user = user_fixture()

      message =
        message_fixture(%{
          content: "Simple message",
          blocks: []
        })

      params = %{
        "message" => message,
        "current_user" => user
      }

      {:ok, _lv, html} = live_isolated(conn, TestLiveView, session: params)

      assert html =~ "Simple message"
      assert html =~ "message-section"
    end

    test "renders reactions for authenticated user", %{conn: conn} do
      user = user_fixture()

      message =
        message_fixture(%{
          reactions: [
            %{"emoji" => "👍", "users" => [user.id, 2]},
            %{"emoji" => "❤️", "users" => [3]}
          ]
        })

      params = %{
        "message" => message,
        "current_user" => user
      }

      {:ok, _lv, html} = live_isolated(conn, TestLiveView, session: params)

      assert html =~ "👍"
      assert html =~ "❤️"
      # count for thumbs up
      assert html =~ "2"
      # count for heart
      assert html =~ "1"
      assert html =~ "toggle_reaction"
    end

    test "renders reactions for unauthenticated user", %{conn: conn} do
      message =
        message_fixture(%{
          reactions: [
            %{"emoji" => "👍", "users" => [1, 2]},
            %{"emoji" => "❤️", "users" => [3]}
          ]
        })

      params = %{
        "message" => message,
        "current_user" => nil
      }

      {:ok, _lv, html} = live_isolated(conn, TestLiveView, session: params)

      assert html =~ "👍"
      assert html =~ "❤️"
      # count for thumbs up
      assert html =~ "2"
      # count for heart
      assert html =~ "1"
      # no interactive buttons
      refute html =~ "toggle_reaction"
    end

    test "renders emoji picker for authenticated user", %{conn: conn} do
      user = user_fixture()
      message = message_fixture()

      params = %{
        "message" => message,
        "current_user" => user
      }

      {:ok, _lv, html} = live_isolated(conn, TestLiveView, session: params)

      assert html =~ "add_reaction"
      assert html =~ "dropdown"
      assert html =~ "😊"
    end

    test "does not render emoji picker for unauthenticated user", %{conn: conn} do
      message = message_fixture()

      params = %{
        "message" => message,
        "current_user" => nil
      }

      {:ok, _lv, html} = live_isolated(conn, TestLiveView, session: params)

      refute html =~ "add_reaction"
      refute html =~ "dropdown"
    end

    test "renders empty reactions list", %{conn: conn} do
      user = user_fixture()
      message = message_fixture(%{reactions: []})

      params = %{
        "message" => message,
        "current_user" => user
      }

      {:ok, _lv, html} = live_isolated(conn, TestLiveView, session: params)

      # Should still render emoji picker for authenticated user
      assert html =~ "dropdown"
      assert html =~ "😊"
    end
  end
end
