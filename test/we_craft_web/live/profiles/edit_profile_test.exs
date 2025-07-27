defmodule WeCraftWeb.Profiles.EditProfileTest do
  @moduledoc """
  Tests for the EditProfile LiveView.
  """
  use WeCraftWeb.ConnCase, async: true

  alias WeCraft.Accounts.Scope

  import Phoenix.LiveViewTest

  alias WeCraft.Profiles

  describe "Edit Profile LiveView" do
    setup :register_and_log_in_user

    test "renders edit profile page", %{conn: conn, user: user} do
      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))
      {:ok, _lv, html} = live(conn, ~p"/profile/edit")

      assert html =~ "Edit Your Profile"
      assert html =~ "Bio"
      assert html =~ "Save Profile"
    end

    test "updates profile successfully", %{conn: conn, user: user} do
      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))
      {:ok, lv, _html} = live(conn, ~p"/profile/edit")

      bio_text = "I am a passionate software engineer with 5 years of experience."

      lv
      |> form("#profile-form", profile: %{bio: bio_text})
      |> render_submit()

      assert render(lv) =~ "Profile updated successfully!"
      assert render(lv) =~ bio_text

      # Verify the profile was actually saved
      profile = Profiles.get_profile_by_user_id(user.id)
      assert profile.bio == bio_text
    end

    test "shows validation errors", %{conn: conn, user: user} do
      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))
      {:ok, lv, _html} = live(conn, ~p"/profile/edit")

      lv
      |> form("#profile-form", profile: %{bio: ""})
      |> render_submit()

      assert render(lv) =~ "can&#39;t be blank"
    end
  end
end
