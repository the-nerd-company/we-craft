defmodule WeCraftWeb.DmErrorPathsTest do
  @moduledoc """
  Tests for DM LiveView error/ignored branches (empty message, reaction paths).
  """
  use WeCraftWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import WeCraft.ChatsFixtures
  import WeCraft.AccountsFixtures, only: [user_fixture: 0]

  test "empty message submission ignored" do
    %{conn: conn, user: user} = register_and_log_in_user(%{conn: build_conn()})
    recipient = user_fixture()
    chat = dm_chat_fixture(%{user1: user, user2: recipient})
    {:ok, lv, html} = live(conn, ~p"/dms/#{chat.id}")
    assert html =~ "Start your conversation"
    render_submit(form(lv, "form[phx-submit=send_message]", %{content: ""}))
    assert render(lv) =~ "Start your conversation"
  end
end
