defmodule WeCraft.CRM.CRMPermissionsTest do
  @moduledoc """
  Tests for the CRMPermissions module.
  """
  use ExUnit.Case, async: true
  alias WeCraft.CRM.CRMPermissions

  defp project(owner_id), do: %WeCraft.Projects.Project{owner_id: owner_id}
  defp scope(user_id), do: %WeCraft.Accounts.Scope{user: %{id: user_id}}

  describe "can_create_contact?/1" do
    test "returns true when project owner matches scope user" do
      params = %{project: project(1), scope: scope(1)}
      assert CRMPermissions.can_create_contact?(params)
    end

    test "returns false when project owner does not match scope user" do
      params = %{project: project(1), scope: scope(2)}
      refute CRMPermissions.can_create_contact?(params)
    end
  end

  describe "can_create_contacts?/1" do
    test "always returns false" do
      assert CRMPermissions.can_create_contacts?(%{}) == false
    end
  end

  describe "can_view_contacts?/1" do
    test "returns true when project owner matches scope user" do
      params = %{project: project(1), scope: scope(1)}
      assert CRMPermissions.can_view_contacts?(params)
    end

    test "returns false when project owner does not match scope user" do
      params = %{project: project(1), scope: scope(2)}
      refute CRMPermissions.can_view_contacts?(params)
    end

    test "returns false when scope is nil" do
      params = %{project: project(1), scope: nil}
      refute CRMPermissions.can_view_contacts?(params)
    end
  end

  describe "can_view_contact?/1" do
    test "always returns false" do
      assert CRMPermissions.can_view_contact?(%{}) == false
    end
  end
end
