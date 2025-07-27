defmodule WeCraftWeb.Projects.MeetingTest do
  @moduledoc """
  Tests for the Meeting LiveView.
  """
  use WeCraftWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import WeCraft.AccountsFixtures
  import WeCraft.ProjectsFixtures
  import WeCraft.ChatsFixtures

  describe "mount/render" do
    test "renders meeting container with correct data attributes" do
      user = user_fixture()
      project = project_fixture(%{owner: user})
      chat = chat_fixture(%{project: project, is_main: true, name: "General", type: "channel"})

      # Authenticate user
      conn = log_in_user(build_conn(), user)

      {:ok, _view, html} = live(conn, ~p"/project/#{project.id}/channels/#{chat.id}/meeting")

      # Container id
      assert html =~ ~s(id="room")
      # Redirect URL attribute
      assert html =~ ~s(data-redirect-url="/project/#{project.id}")
      # Room name contains chat room_uuid
      assert html =~ ~s(data-room-name="#{chat.room_uuid}")
      # User name/email attributes
      assert html =~ ~s(data-user-name="#{user.name}")
      assert html =~ ~s(data-user-email="#{user.email}")
    end
  end
end
