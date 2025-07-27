defmodule WeCraft.Projects.ProjectPermissions do
  @moduledoc """
  Module for handling project permissions.
  """
  alias WeCraft.Accounts.User
  alias WeCraft.Projects.Project

  def can_update_project?(%Project{}, nil), do: false

  def can_update_project?(%Project{owner_id: owner_id}, %{user: %User{id: user_id}}) do
    owner_id == user_id
  end
end
