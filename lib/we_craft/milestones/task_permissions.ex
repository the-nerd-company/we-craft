defmodule WeCraft.Milestones.TaskPermissions do
  @moduledoc """
  Module for handling task permissions.
  Since tasks belong to milestones which belong to projects, task permissions delegate to project permissions.
  """
  alias WeCraft.Projects.ProjectPermissions

  def can_create_task?(milestone, scope) do
    # If project is already loaded, use it; otherwise preload it
    milestone =
      case milestone.project do
        %Ecto.Association.NotLoaded{} -> WeCraft.Repo.preload(milestone, :project)
        _ -> milestone
      end

    ProjectPermissions.can_update_project?(milestone.project, scope)
  end

  def can_update_task?(task, scope) do
    task = WeCraft.Repo.preload(task, milestone: :project)
    ProjectPermissions.can_update_project?(task.milestone.project, scope)
  end

  def can_delete_task?(task, scope) do
    task = WeCraft.Repo.preload(task, milestone: :project)
    ProjectPermissions.can_update_project?(task.milestone.project, scope)
  end

  def can_view_tasks?(milestone, scope) do
    milestone = WeCraft.Repo.preload(milestone, :project)
    ProjectPermissions.can_update_project?(milestone.project, scope)
  end

  def can_view_task?(task, scope) do
    task = WeCraft.Repo.preload(task, milestone: :project)
    ProjectPermissions.can_update_project?(task.milestone.project, scope)
  end
end
