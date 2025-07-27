defmodule WeCraft.Milestones.MilestonePermissions do
  @moduledoc """
  Module for handling milestone permissions.
  Since milestones belong to projects, milestone permissions delegate to project permissions.
  """
  alias WeCraft.Projects.ProjectPermissions

  def can_create_milestone?(project, scope) do
    ProjectPermissions.can_update_project?(project, scope)
  end

  def can_update_milestone?(project, scope) do
    ProjectPermissions.can_update_project?(project, scope)
  end

  def can_delete_milestone?(project, scope) do
    ProjectPermissions.can_update_project?(project, scope)
  end

  def can_view_milestones?(project, scope) do
    # For now, allow anyone to view milestones for public projects
    # In the future, this could be more restrictive
    ProjectPermissions.can_update_project?(project, scope)
  end

  def can_view_milestone?(milestone, scope) do
    # Load the project if not already loaded
    milestone = WeCraft.Repo.preload(milestone, :project)
    can_view_milestones?(milestone.project, scope)
  end
end
