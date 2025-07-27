defmodule WeCraft.CRM.CRMPermissions do
  @moduledoc """
  Provides permission checks for CRM resources.
  """
  alias WeCraft.Accounts.Scope
  alias WeCraft.Projects.Project

  def can_create_contact?(%{
        project: %Project{owner_id: owner_id},
        scope: %Scope{} = %{user: %{id: user_id}}
      }) do
    owner_id == user_id
  end

  def can_create_contacts?(_params), do: false

  def can_view_contacts?(%{project: %Project{owner_id: owner_id}, scope: %Scope{} = scope}) do
    owner_id == scope.user.id
  end

  def can_view_contacts?(_), do: false

  def can_view_contact?(_), do: false
end
