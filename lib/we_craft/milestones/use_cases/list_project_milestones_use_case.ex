defmodule WeCraft.Milestones.UseCases.ListProjectMilestonesUseCase do
  @moduledoc """
  Use case for listing project milestones with proper authorization.
  """

  alias WeCraft.Milestones.Infrastructure.Ecto.MilestoneRepositoryEcto
  alias WeCraft.Milestones.MilestonePermissions
  alias WeCraft.Projects.Infrastructure.Ecto.ProjectRepositoryEcto

  def list_project_milestones(%{project_id: project_id, scope: scope}) do
    case ProjectRepositoryEcto.get_project(project_id) do
      nil ->
        {:error, :project_not_found}

      project ->
        if MilestonePermissions.can_view_milestones?(project, scope) do
          MilestoneRepositoryEcto.list_project_milestones(project_id)
        else
          {:error, :unauthorized}
        end
    end
  end
end
