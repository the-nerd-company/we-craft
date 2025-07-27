defmodule WeCraft.Pages.PagePermissionsTest do
  @moduledoc """
  Unit tests for the PagePermissions module.
  """
  use ExUnit.Case, async: true

  alias WeCraft.Pages.PagePermissions

  describe "can_create_page?/1" do
    test "returns false if scope is nil" do
      project = %{owner_id: 1}
      assert PagePermissions.can_create_page?(%{project: project, scope: nil}) == false
    end

    test "returns true if user is project owner" do
      user = %{id: 42}
      project = %{owner_id: 42}
      scope = %{user: user}
      assert PagePermissions.can_create_page?(%{project: project, scope: scope}) == true
    end

    test "returns false if user is not project owner" do
      user = %{id: 99}
      project = %{owner_id: 42}
      scope = %{user: user}
      assert PagePermissions.can_create_page?(%{project: project, scope: scope}) == false
    end
  end

  describe "can_view_page?/1" do
    test "returns true if project is public" do
      project = %{is_public: true}
      page = %{project: project}
      scope = %{user: %{id: 1}}
      assert PagePermissions.can_view_page?(%{page: page, scope: scope}) == true
    end

    test "returns true if user is owner of private project" do
      project = %{is_public: false, owner_id: 42}
      page = %{project: project}
      scope = %{user: %{id: 42}}
      assert PagePermissions.can_view_page?(%{page: page, scope: scope}) == true
    end

    test "returns false if user is not owner of private project" do
      project = %{is_public: false, owner_id: 42}
      page = %{project: project}
      scope = %{user: %{id: 99}}
      assert PagePermissions.can_view_page?(%{page: page, scope: scope}) == false
    end
  end
end
