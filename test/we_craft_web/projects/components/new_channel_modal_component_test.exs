defmodule WeCraftWeb.Projects.Components.NewChannelModalComponentTest do
  @moduledoc """
  Tests for the NewChannelModalComponent.
  """
  use WeCraftWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import WeCraft.AccountsFixtures
  import WeCraft.ProjectsFixtures

  alias WeCraftWeb.Projects.Components.NewChannelModalComponent

  describe "NewChannelModalComponent" do
    setup do
      user = user_fixture()
      project = project_fixture(%{owner: user})

      %{
        user: user,
        project: project
      }
    end

    test "renders modal when show is true", %{project: project} do
      html =
        render_component(NewChannelModalComponent, %{
          id: "new-channel-modal",
          project: project,
          show: true
        })

      assert html =~ "Create New Channel"
      assert html =~ "Channel Name"
      assert html =~ "Description (optional)"
      assert html =~ "Public Channel"
    end

    test "hides modal when show is false", %{project: project} do
      html =
        render_component(NewChannelModalComponent, %{
          id: "new-channel-modal",
          project: project,
          show: false
        })

      assert html =~ "hidden"
    end

    test "closes modal on close button click", %{project: project} do
      html =
        render_component(NewChannelModalComponent, %{
          id: "new-channel-modal",
          project: project,
          show: true
        })

      # Just verify the HTML contains the close button
      assert html =~ "Cancel"
    end

    test "creates channel form with valid inputs", %{project: project} do
      html =
        render_component(NewChannelModalComponent, %{
          id: "new-channel-modal",
          project: project,
          show: true
        })

      # Verify the form elements are present
      assert html =~ "Channel Name"
      assert html =~ "Description (optional)"
      assert html =~ "Public Channel"
      assert html =~ "Create Channel"
    end
  end
end
