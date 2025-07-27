defmodule WeCraft.Milestones.UseCases.DeleteMilestoneUseCase do
  @moduledoc """
  Use case for deleting a milestone with proper authorization.
  """

  alias WeCraft.Milestones.Infrastructure.Ecto.MilestoneRepositoryEcto
  alias WeCraft.Milestones.MilestonePermissions

  def delete_milestone(%{milestone_id: milestone_id, scope: scope}) do
    case MilestoneRepositoryEcto.get_milestone_with_project(milestone_id) do
      {:error, :not_found} ->
        {:error, :not_found}

      {:ok, milestone} ->
        if MilestonePermissions.can_delete_milestone?(milestone.project, scope) do
          MilestoneRepositoryEcto.delete_milestone(milestone)
        else
          {:error, :unauthorized}
        end
    end
  end
end
