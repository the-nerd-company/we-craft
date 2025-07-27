defmodule WeCraft.Tickets.TicketsPermissions do
  @moduledoc """
  Permissions for viewing and managing tickets within a project.
  """

  alias WeCraft.Accounts.Scope
  alias WeCraft.Projects.Project

  def can_view_tickets?(%{
        project: %Project{} = %{owner_id: owner_id},
        scope: %Scope{} = %{user: %{id: user_id}}
      }) do
    user_id == owner_id
  end

  def can_view_tickets?(_) do
    false
  end
end
