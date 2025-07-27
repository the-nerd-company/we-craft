defmodule WeCraft.Milestones.UseCases.UpdateMilestoneUseCase do
  @moduledoc """
  Use case for updating a milestone with proper authorization.
  """

  alias WeCraft.Milestones.Infrastructure.Ecto.MilestoneRepositoryEcto
  alias WeCraft.Milestones.MilestonePermissions
  alias WeCraft.Milestones.MilestoneUpdateStatus
  alias WeCraft.Projects.Infrastructure.Ecto.ProjectEventsRepositoryEcto

  def update_milestone(%{milestone_id: milestone_id, attrs: attrs, scope: scope}) do
    case MilestoneRepositoryEcto.get_milestone_with_project(milestone_id) do
      {:error, :not_found} ->
        {:error, :not_found}

      {:ok, milestone} ->
        if MilestonePermissions.can_update_milestone?(milestone.project, scope) do
          res = MilestoneRepositoryEcto.update_milestone(milestone, attrs)
          maybe_create_project_events(milestone, attrs, scope)
          res
        else
          {:error, :unauthorized}
        end
    end
  end

  defp maybe_create_project_events(milestone, attrs, scope) do
    MilestoneUpdateStatus.generate_events(milestone, attrs, scope)
    |> Enum.each(fn event ->
      ProjectEventsRepositoryEcto.create_event(event)
    end)

    :ok
  end
end
