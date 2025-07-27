defmodule WeCraftWeb.ListDmTest do
  @moduledoc """
  Tests for the ListDm LiveView (DM list / redirect behavior).
  """
  use WeCraftWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import WeCraft.ChatsFixtures
  import WeCraft.AccountsFixtures, only: [user_fixture: 0]

  describe "mount" do
    test "renders empty state when no DMs", %{conn: conn} do
      %{conn: conn} = register_and_log_in_user(%{conn: conn})
      {:ok, _lv, html} = live(conn, ~p"/dms")
      assert html =~ "No Direct Messages"
      assert html =~ "You don&#39;t have any direct message conversations yet."
    end

    test "redirects to first DM when at least one exists", %{conn: conn} do
      %{conn: conn, user: user} = register_and_log_in_user(%{conn: conn})
      recipient = user_fixture()
      chat = dm_chat_fixture(%{user1: user, user2: recipient})

      assert {:error, {:live_redirect, %{to: to}}} = live(conn, ~p"/dms")
      assert to == ~p"/dms/#{chat.id}"
    end
  end

  describe "handle_info dm_created" do
    test "redirects to newly created first DM", %{conn: conn} do
      %{conn: conn, user: user} = register_and_log_in_user(%{conn: conn})
      {:ok, lv, _html} = live(conn, ~p"/dms")
      recipient = user_fixture()
      dm = dm_chat_fixture(%{user1: user, user2: recipient})

      # Simulate broadcaster event
      send(lv.pid, {WeCraft.Chats, [:dm_created, dm]})

      # Expect redirect (navigation) to /dms/:id
      assert_redirect(lv, ~p"/dms/#{dm.id}")
    end
  end
end
