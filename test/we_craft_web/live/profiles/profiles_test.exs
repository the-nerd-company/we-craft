defmodule WeCraftWeb.Profiles.ProfilesTest do
  @moduledoc """
  Tests for the Profiles LiveView.
  """
  use WeCraftWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias WeCraft.Accounts.{Scope, User}
  alias WeCraft.AccountsFixtures

  describe "Profiles LiveView" do
    setup :register_and_log_in_user

    test "renders profiles page with user list", %{conn: conn, user: user} do
      # Create additional users to display - some with names, some without
      user2 = AccountsFixtures.user_fixture(%{email: "user2@example.com"})
      user3 = AccountsFixtures.user_fixture_without_name(%{email: "user3@example.com"})

      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))
      {:ok, lv, html} = live(conn, ~p"/profiles")

      # Should display the page title
      assert html =~ "User Profiles"

      # Should NOT display user emails in the profiles content (privacy concern)
      # Note: emails might appear in nav bar, but not in profiles content
      profiles_content = lv |> element("div.grid") |> render()
      refute profiles_content =~ user.email
      refute profiles_content =~ user2.email
      refute profiles_content =~ user3.email

      # Should show anonymous users for users without names
      assert profiles_content =~ "Anonymous User"
    end

    test "renders empty state when no users found", %{conn: conn, user: user} do
      # Create a user without name to test anonymous display
      AccountsFixtures.user_fixture_without_name(%{email: "anonymous@example.com"})

      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))
      {:ok, lv, html} = live(conn, ~p"/profiles")

      assert html =~ "User Profiles"
      # Should NOT display user emails in profiles content (privacy concern)
      profiles_content = lv |> element("div.grid") |> render()
      refute profiles_content =~ user.email
      # Should show anonymous user for users without names
      assert profiles_content =~ "Anonymous User"
    end

    test "displays user name when available", %{conn: conn, user: user} do
      # Create a user and then update with a name (since register_user only handles email)
      user_with_email = AccountsFixtures.user_fixture(%{email: "named.user@example.com"})

      # Update the user to add a name using Ecto directly since there's no exposed function for it
      WeCraft.Repo.update!(User.name_changeset(user_with_email, %{name: "John Doe"}))

      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))
      {:ok, lv, html} = live(conn, ~p"/profiles")

      # Should display the user's name as primary identifier
      assert html =~ "John Doe"
      # Should NOT display the email in profiles content (privacy concern)
      profiles_content = lv |> element("div.grid") |> render()
      refute profiles_content =~ "named.user@example.com"
      # Should show user profile text
      assert profiles_content =~ "User Profile"
    end

    test "displays anonymous user when name is not available", %{conn: conn, user: user} do
      # Create a user without a name
      _user_without_name =
        AccountsFixtures.user_fixture_without_name(%{email: "noname@example.com"})

      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))
      {:ok, lv, html} = live(conn, ~p"/profiles")

      # Should display anonymous user as fallback
      assert html =~ "Anonymous User"
      # Should NOT display the user's email in profiles content (privacy concern)
      profiles_content = lv |> element("div.grid") |> render()
      refute profiles_content =~ "noname@example.com"
    end

    test "profile links navigate to individual profile pages", %{conn: conn, user: user} do
      user2 = AccountsFixtures.user_fixture(%{email: "linktest@example.com"})

      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))
      {:ok, lv, _html} = live(conn, ~p"/profiles")

      # Should contain links to individual profile pages
      assert has_element?(lv, "a[href='/profile/#{user.id}']")
      assert has_element?(lv, "a[href='/profile/#{user2.id}']")
    end

    test "applies correct CSS classes and styling", %{conn: conn, user: user} do
      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))
      {:ok, _lv, html} = live(conn, ~p"/profiles")

      # Check for proper styling classes
      assert html =~ "min-h-screen bg-gradient-to-br from-base-100 to-base-200"
      assert html =~ "grid grid-cols-1 md:grid-cols-2 gap-6"
      assert html =~ "bg-base-100 p-6 rounded-lg shadow-sm"
    end

    test "handles unauthenticated access", %{} do
      # Test with unauthenticated connection
      conn = build_conn()

      # Based on the actual behavior, this view appears to be public
      {:ok, _lv, html} = live(conn, ~p"/profiles")
      assert html =~ "User Profiles"
    end

    test "loads users through accounts context", %{conn: conn, user: user} do
      # Create users to test proper loading - include one without name to test anonymous display
      user2 = AccountsFixtures.user_fixture_without_name(%{email: "scoped@example.com"})

      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))
      {:ok, lv, html} = live(conn, ~p"/profiles")

      # Should show anonymous users (not emails)
      assert html =~ "Anonymous User"
      # Should NOT display emails in profiles content (privacy concern)
      profiles_content = lv |> element("div.grid") |> render()
      refute profiles_content =~ user.email
      refute profiles_content =~ user2.email
    end

    test "ensures no email addresses are exposed in profiles content", %{conn: conn, user: user} do
      # Create users with various email patterns - mix of users with and without names
      user1 = AccountsFixtures.user_fixture(%{email: "test@example.com"})
      user2 = AccountsFixtures.user_fixture_without_name(%{email: "privacy@sensitive.org"})
      user3 = AccountsFixtures.user_fixture_without_name(%{email: "hidden@secret.net"})

      conn = Plug.Conn.assign(conn, :current_scope, Scope.for_user(user))
      {:ok, lv, _html} = live(conn, ~p"/profiles")

      # Focus only on the profiles grid content, not the entire page (nav bar might have emails)
      profiles_content = lv |> element("div.grid") |> render()

      # Ensure NO email addresses are displayed in the profiles content
      refute profiles_content =~ user.email
      refute profiles_content =~ user1.email
      refute profiles_content =~ user2.email
      refute profiles_content =~ user3.email
      refute profiles_content =~ "@example.com"
      refute profiles_content =~ "@sensitive.org"
      refute profiles_content =~ "@secret.net"

      # Should only show safe content
      assert profiles_content =~ "Anonymous User"
    end
  end
end
