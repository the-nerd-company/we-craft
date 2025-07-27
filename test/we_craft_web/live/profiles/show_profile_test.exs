defmodule WeCraftWeb.Profiles.ShowProfileTest do
  @moduledoc """
  Tests for the ShowProfile LiveView.
  """
  use WeCraftWeb.ConnCase, async: true

  alias WeCraft.Accounts.Scope
  alias WeCraft.Profiles

  import Phoenix.LiveViewTest

  describe "Show Profile LiveView" do
    setup :register_and_log_in_user

    test "renders profile page with existing profile", %{conn: conn, user: user} do
      {:ok, _profile} =
        Profiles.create_user_profile(%{
          attrs: %{bio: "I am a software engineer.", user_id: user.id}
        })

      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))
      {:ok, _lv, html} = live(conn, ~p"/profile/#{user.id}")

      assert html =~ user.email
      assert html =~ "I am a software engineer."
      assert html =~ "Technical Skills"
      assert html =~ "What I Can Offer"
    end

    test "renders profile page with skills", %{conn: conn, user: user} do
      # Create a profile with skills
      {:ok, _profile} =
        Profiles.create_user_profile(%{
          attrs: %{
            bio: "I am a software engineer.",
            skills: ["elixir", "phoenix", "javascript", "react"],
            user_id: user.id
          }
        })

      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))
      {:ok, _lv, html} = live(conn, ~p"/profile/#{user.id}")

      assert html =~ user.email
      assert html =~ "I am a software engineer."
      assert html =~ "Technical Skills"
      assert html =~ "elixir"
      assert html =~ "phoenix"
      assert html =~ "javascript"
      assert html =~ "react"
    end

    test "renders profile page with offers", %{conn: conn, user: user} do
      # Create a profile with offers
      {:ok, _profile} =
        Profiles.create_user_profile(%{
          attrs: %{
            bio: "I am a software engineer.",
            offers: ["frontend", "backend", "ui/ux", "mobile"],
            user_id: user.id
          }
        })

      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))
      {:ok, _lv, html} = live(conn, ~p"/profile/#{user.id}")

      assert html =~ user.email
      assert html =~ "I am a software engineer."
      assert html =~ "What I Can Offer"
      assert html =~ "frontend"
      assert html =~ "backend"
      assert html =~ "ui/ux"
      assert html =~ "mobile"
    end

    test "renders profile page with both skills and offers", %{conn: conn, user: user} do
      # Create a profile with both skills and offers
      {:ok, _profile} =
        Profiles.create_user_profile(%{
          attrs: %{
            bio: "I am a full-stack developer.",
            skills: ["elixir", "phoenix"],
            offers: ["frontend", "testing"],
            user_id: user.id
          }
        })

      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))
      {:ok, _lv, html} = live(conn, ~p"/profile/#{user.id}")

      assert html =~ user.email
      assert html =~ "I am a full-stack developer."

      # Check skills section
      assert html =~ "Technical Skills"
      assert html =~ "elixir"
      assert html =~ "phoenix"

      # Check offers section
      assert html =~ "What I Can Offer"
      assert html =~ "frontend"
      assert html =~ "testing"
    end

    test "renders skills section even when no skills", %{conn: conn, user: user} do
      # Create a profile without skills
      {:ok, _profile} =
        Profiles.create_user_profile(%{
          attrs: %{bio: "I am a software engineer.", user_id: user.id}
        })

      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))
      {:ok, _lv, html} = live(conn, ~p"/profile/#{user.id}")

      assert html =~ user.email
      assert html =~ "I am a software engineer."
      assert html =~ "Technical Skills"
    end

    test "renders skills section even when skills is empty array", %{conn: conn, user: user} do
      # Create a profile with empty skills array
      {:ok, _profile} =
        Profiles.create_user_profile(%{
          attrs: %{
            bio: "I am a software engineer.",
            skills: [],
            user_id: user.id
          }
        })

      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))
      {:ok, _lv, html} = live(conn, ~p"/profile/#{user.id}")

      assert html =~ user.email
      assert html =~ "I am a software engineer."
      assert html =~ "Technical Skills"
    end

    test "renders offers section even when no offers", %{conn: conn, user: user} do
      # Create a profile without offers
      {:ok, _profile} =
        Profiles.create_user_profile(%{
          attrs: %{bio: "I am a software engineer.", user_id: user.id}
        })

      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))
      {:ok, _lv, html} = live(conn, ~p"/profile/#{user.id}")

      assert html =~ user.email
      assert html =~ "I am a software engineer."
      assert html =~ "What I Can Offer"
    end

    test "renders offers section even when offers is empty array", %{conn: conn, user: user} do
      # Create a profile with empty offers array
      {:ok, _profile} =
        Profiles.create_user_profile(%{
          attrs: %{
            bio: "I am a software engineer.",
            offers: [],
            user_id: user.id
          }
        })

      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))
      {:ok, _lv, html} = live(conn, ~p"/profile/#{user.id}")

      assert html =~ user.email
      assert html =~ "I am a software engineer."
      assert html =~ "What I Can Offer"
    end

    test "renders profile page with placeholder bio", %{conn: conn, user: user} do
      # Create a profile with placeholder bio
      {:ok, _profile} =
        Profiles.create_user_profile(%{
          attrs: %{bio: "Tell us about yourself...", user_id: user.id}
        })

      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))
      {:ok, _lv, html} = live(conn, ~p"/profile/#{user.id}")

      assert html =~ user.email
      assert html =~ "This user hasn&#39;t added a bio yet."
    end

    test "handles profile not found for non-existent user", %{conn: conn, user: user} do
      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))

      # Expect a redirect when user profile is not found
      assert {:error, {:live_redirect, %{to: "/", flash: %{"error" => "Profile not found"}}}} =
               live(conn, ~p"/profile/99999")
    end
  end
end
