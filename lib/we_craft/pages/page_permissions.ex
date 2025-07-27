defmodule WeCraft.Pages.PagePermissions do
  @moduledoc """
  Handles permissions related to page operations.
  This module checks if a user has the necessary permissions to perform actions on pages.
  """

  def can_create_page?(%{project: _project, scope: nil}), do: false

  def can_create_page?(%{project: project, scope: scope}) do
    project.owner_id == scope.user.id
  end

  def can_view_page?(%{page: %{project: %{is_public: true}}, scope: _scope}), do: true

  def can_view_page?(%{page: %{project: %{owner_id: owner_id}}, scope: %{user: user}}),
    do: user.id == owner_id
end
