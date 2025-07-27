defmodule WeCraft.Tickets.TicketsPermissionsTest do
  @moduledoc """
  Tests for ticket permissions.
  """
  use ExUnit.Case, async: true

  alias WeCraft.Tickets.TicketsPermissions

  defp project(owner_id), do: %WeCraft.Projects.Project{owner_id: owner_id}
  defp scope(user_id), do: %WeCraft.Accounts.Scope{user: %{id: user_id}}

  describe "can_view_tickets?/1" do
    test "returns true when user is project owner" do
      owner_id = 42
      params = %{project: project(owner_id), scope: scope(owner_id)}
      assert TicketsPermissions.can_view_tickets?(params)
    end

    test "returns false when user is not project owner" do
      params = %{project: project(1), scope: scope(2)}
      refute TicketsPermissions.can_view_tickets?(params)
    end

    test "returns false for missing or invalid params" do
      refute TicketsPermissions.can_view_tickets?(%{})
      refute TicketsPermissions.can_view_tickets?(nil)
      refute TicketsPermissions.can_view_tickets?(%{project: nil, scope: nil})
    end
  end
end
