defmodule WeCraftWeb.DmTest do
  @moduledoc """
  Tests for the Direct Message (DM) LiveView.
  """
  use WeCraftWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import WeCraft.ChatsFixtures
  import WeCraft.AccountsFixtures, only: [user_fixture: 0]

  alias WeCraft.Chats.Message
  alias WeCraft.Repo

  describe "mount (empty chat)" do
    setup %{conn: conn} do
      %{conn: conn, user: user} = register_and_log_in_user(%{conn: conn})
      recipient = user_fixture()
      chat = dm_chat_fixture(%{user1: user, user2: recipient})
      {:ok, %{conn: conn, user: user, recipient: recipient, chat: chat}}
    end

    test "renders empty state and recipient header", %{
      conn: conn,
      chat: chat,
      recipient: recipient
    } do
      {:ok, _lv, html} = live(conn, ~p"/dms/#{chat.id}")
      assert html =~ "Start your conversation"
      assert html =~ (recipient.name || recipient.email)
      # Sidebar should list the DM link
      assert html =~ ~s|/dms/#{chat.id}|
    end
  end

  describe "sending messages" do
    setup %{conn: conn} do
      %{conn: conn, user: user} = register_and_log_in_user(%{conn: conn})
      recipient = user_fixture()
      chat = dm_chat_fixture(%{user1: user, user2: recipient})
      {:ok, %{conn: conn, user: user, recipient: recipient, chat: chat}}
    end

    test "submitting non-empty content broadcasts and renders message", %{conn: conn, chat: chat} do
      {:ok, lv, _html} = live(conn, ~p"/dms/#{chat.id}")

      # Submit message
      html_after_submit =
        lv
        |> form("form[phx-submit=send_message]", %{content: "Hello there"})
        |> render_submit()

      # First render (immediately after submit) might not yet include broadcasted message
      refute html_after_submit =~ "Hello there"

      # Subsequent render should include the new message after handle_info processes PubSub
      html_after_broadcast = render(lv)
      assert html_after_broadcast =~ "Hello there"
    end

    test "submitting empty content does nothing", %{conn: conn, chat: chat} do
      {:ok, lv, html} = live(conn, ~p"/dms/#{chat.id}")
      assert html =~ "Start your conversation"

      _html_after =
        lv
        |> form("form[phx-submit=send_message]", %{content: ""})
        |> render_submit()

      # Still empty state, no message content rendered
      html2 = render(lv)
      assert html2 =~ "Start your conversation"
    end
  end

  describe "sidebar with multiple DMs" do
    setup %{conn: conn} do
      %{conn: conn, user: user} = register_and_log_in_user(%{conn: conn})
      recipient1 = user_fixture()
      recipient2 = user_fixture()
      chat1 = dm_chat_fixture(%{user1: user, user2: recipient1})
      chat2 = dm_chat_fixture(%{user1: user, user2: recipient2})

      {:ok,
       %{
         conn: conn,
         user: user,
         chat1: chat1,
         chat2: chat2,
         recipient1: recipient1,
         recipient2: recipient2
       }}
    end

    test "lists all DMs and highlights current one", %{
      conn: conn,
      chat2: current_chat,
      chat1: other_chat
    } do
      {:ok, _lv, html} = live(conn, ~p"/dms/#{current_chat.id}")
      assert html =~ ~s|/dms/#{current_chat.id}|
      assert html =~ ~s|/dms/#{other_chat.id}|
      # Highlight class string includes bg-primary/10 and border-l-primary for active chat
      assert html =~ ~r|/dms/#{current_chat.id}"[^>]*class="[^"]*bg-primary/10|
    end
  end

  describe "messages ordering" do
    setup %{conn: conn} do
      %{conn: conn, user: user} = register_and_log_in_user(%{conn: conn})
      recipient = user_fixture()
      chat = dm_chat_fixture(%{user1: user, user2: recipient})
      # Controlled timestamps to ensure deterministic ordering
      older_ts = DateTime.utc_now() |> DateTime.add(-3600, :second)
      newer_ts = DateTime.add(older_ts, 10, :second)

      # Insert older message
      %Message{}
      |> Message.changeset(%{
        chat_id: chat.id,
        sender_id: user.id,
        content: "Older",
        timestamp: older_ts
      })
      |> Repo.insert!()

      # Insert newer message
      %Message{}
      |> Message.changeset(%{
        chat_id: chat.id,
        sender_id: recipient.id,
        content: "Newer",
        timestamp: newer_ts
      })
      |> Repo.insert!()

      {:ok, %{conn: conn, chat: chat}}
    end

    test "renders messages sorted by timestamp", %{conn: conn, chat: chat} do
      {:ok, _lv, html} = live(conn, ~p"/dms/#{chat.id}")
      # Extract only the messages container to avoid sidebar last-message previews
      messages_section =
        case Regex.run(
               ~r/<div id="messages-container"[\s\S]*?(<\/div>)<\/div><!-- Message Input/,
               html
             ) do
          nil -> html
          [full, _closing] -> full
        end

      older_index = :binary.match(messages_section, "Older") |> elem(0)
      newer_index = :binary.match(messages_section, "Newer") |> elem(0)
      assert older_index < newer_index
    end
  end
end
