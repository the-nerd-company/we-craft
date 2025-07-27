defmodule WeCraft.Pages.PagePermissions do
  @moduledoc """
  Handles permissions related to page operations.
  This module checks if a user has the necessary permissions to perform actions on pages.
  """

  def can_create_page?(%{project: _project, scope: nil}), do: false

  def can_create_page?(%{project: project, scope: scope}) do
    project.owner_id == scope.user.id
  end
end
