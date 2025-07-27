defmodule WeCraft.Milestones.UseCases.ListMilestoneTasksUseCase do
  @moduledoc """
  Use case for listing milestone tasks with proper authorization.
  """

  alias WeCraft.Milestones.Infrastructure.Ecto.MilestoneRepositoryEcto
  alias WeCraft.Milestones.Infrastructure.Ecto.TaskRepositoryEcto
  alias WeCraft.Milestones.TaskPermissions

  def list_milestone_tasks(%{milestone_id: milestone_id, scope: scope}) do
    case MilestoneRepositoryEcto.get_milestone(milestone_id) do
      {:error, :not_found} ->
        {:error, :milestone_not_found}

      {:ok, milestone} ->
        if TaskPermissions.can_view_tasks?(milestone, scope) do
          TaskRepositoryEcto.list_milestone_tasks(milestone_id)
        else
          {:error, :unauthorized}
        end
    end
  end
end
