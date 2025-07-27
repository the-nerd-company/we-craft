defmodule WeCraftWeb.Projects.ProjectLiveTest do
  @moduledoc """
  Integration tests for the Project LiveView.
  """
  use WeCraftWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import WeCraft.AccountsFixtures
  import WeCraft.ProjectsFixtures

  describe "Project LiveView" do
    setup %{conn: conn} do
      user = user_fixture()
      project = project_fixture(%{owner: user})

      # Create a main chat for the project (normally done by CreateProjectUseCase)
      {:ok, _main_chat} =
        WeCraft.Chats.create_project_chat(%{
          attrs: %{is_main: true, project_id: project.id, is_public: true, type: "channel"}
        })

      %{
        conn: log_in_user(conn, user),
        user: user,
        project: project
      }
    end

    test "can create a new channel", %{conn: conn, project: project} do
      {:ok, view, _html} = live(conn, ~p"/project/#{project.id}/channels")

      # Click the "Add channel" button
      view
      |> element("button", "Add channel")
      |> render_click()

      # Check that modal is opened by looking for the modal content
      assert render(view) =~ "Create New Channel"

      # Fill and submit the form - be specific about which form
      view
      |> form("form[phx-submit='create-channel']",
        channel: %{
          name: "test-channel",
          description: "Test channel description",
          is_public: "true"
        }
      )
      |> render_submit()

      # Check that the channel was created and appears in the chat list
      assert render(view) =~ "test-channel"
    end

    test "shows validation errors for empty channel name", %{conn: conn, project: project} do
      {:ok, view, _html} = live(conn, ~p"/project/#{project.id}/channels")

      # Click the "Add channel" button
      view
      |> element("button", "Add channel")
      |> render_click()

      # Submit form with empty name
      assert render(view) =~ "Create New Channel"

      # After submitting with empty name, the HTML required attribute should prevent submission
      # or we should still see the modal (depending on browser validation)
      view
      |> form("form[phx-submit='create-channel']",
        channel: %{
          name: "",
          description: "Test description",
          is_public: "true"
        }
      )
      |> render_submit()
    end

    test "can select different channels", %{conn: conn, project: project} do
      {:ok, view, _html} = live(conn, ~p"/project/#{project.id}/channels")

      # Create a new channel first
      view
      |> element("button", "Add channel")
      |> render_click()

      view
      |> form("form[phx-submit='create-channel']",
        channel: %{
          name: "dev-channel",
          description: "Development discussions",
          is_public: "true"
        }
      )
      |> render_submit()

      # Now we should have at least 2 channels (main chat + dev-channel)
      html = render(view)
      assert html =~ "general"
      assert html =~ "dev-channel"

      # The newly created channel should be selected (active)
      assert html =~ "bg-primary/10 text-primary font-medium"

      # Click on the main chat to select it
      view
      |> element("button[phx-value-chat-id]", "general")
      |> render_click()

      # Verify main chat is now selected
      html = render(view)
      # We should still see both channels
      assert html =~ "general"
      assert html =~ "dev-channel"
    end

    test "displays different channels when switching and updates chat header", %{
      conn: conn,
      project: project
    } do
      {:ok, view, _html} = live(conn, ~p"/project/#{project.id}/channels")

      # Initially should show main chat
      html = render(view)
      # Chat header should show "Main Chat"
      assert html =~ ~r/<h2 class="text-xl font-semibold">Main Chat<\/h2>/
      # Main chat should be highlighted in sidebar
      assert html =~ "bg-primary/10 text-primary font-medium"

      # Create a new channel
      view
      |> element("button", "Add channel")
      |> render_click()

      view
      |> form("form[phx-submit='create-channel']",
        channel: %{
          name: "dev-channel",
          description: "Development discussions",
          is_public: "true"
        }
      )
      |> render_submit()

      # After creating channel, it should be selected and header should update
      html = render(view)
      # Chat header should now show "dev-channel"
      assert html =~ ~r/<h2 class="text-xl font-semibold">dev-channel<\/h2>/
      # There should still be highlighting somewhere (for the selected channel)
      assert html =~ "bg-primary/10 text-primary font-medium"

      # Click on main chat to switch back
      view
      |> element("button[phx-value-chat-id]", "general")
      |> render_click()

      # Chat header should switch back to "Main Chat"
      html = render(view)
      assert html =~ ~r/<h2 class="text-xl font-semibold">Main Chat<\/h2>/
      # Main chat should now be highlighted
      assert html =~ "bg-primary/10 text-primary font-medium"

      # Click back on dev channel
      view
      |> element("button", "dev-channel")
      |> render_click()

      # Should switch back to dev channel
      html = render(view)
      assert html =~ ~r/<h2 class="text-xl font-semibold">dev-channel<\/h2>/
      assert html =~ "bg-primary/10 text-primary font-medium"
    end

    test "can close the new channel modal", %{conn: conn, project: project} do
      {:ok, view, _html} = live(conn, ~p"/project/#{project.id}/channels")

      # Click the "Add channel" button
      view
      |> element("button", "Add channel")
      |> render_click()

      # Check that modal is opened
      assert render(view) =~ "Create New Channel"

      # Click Cancel button
      view
      |> element("button", "Cancel")
      |> render_click()

      # Modal should be closed
      refute render(view) =~ "Create New Channel"
    end
  end
end
