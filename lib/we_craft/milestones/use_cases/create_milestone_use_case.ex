defmodule WeCraft.Milestones.UseCases.CreateMilestoneUseCase do
  @moduledoc """
  Use case for creating a milestone in the WeCraft application.
  This module encapsulates the logic for creating a milestone, including validation and persistence.
  """

  alias WeCraft.Milestones.Infrastructure.Ecto.MilestoneRepositoryEcto
  alias WeCraft.Milestones.MilestonePermissions
  alias WeCraft.Milestones.MilestoneUpdateStatus
  alias WeCraft.Projects.Infrastructure.Ecto.ProjectEventsRepositoryEcto
  alias WeCraft.Projects.Infrastructure.Ecto.ProjectRepositoryEcto

  def create_milestone(%{attrs: attrs, scope: scope}) do
    project_id = attrs["project_id"] || attrs[:project_id]

    # Let the repository handle validation errors for missing project_id
    if is_nil(project_id) do
      MilestoneRepositoryEcto.create_milestone(attrs)
    else
      do_create_milestone_with_authorization(attrs, scope, project_id)
    end
  end

  defp do_create_milestone_with_authorization(attrs, scope, project_id) do
    case ProjectRepositoryEcto.get_project(project_id) do
      nil ->
        {:error, :project_not_found}

      project ->
        if MilestonePermissions.can_create_milestone?(project, scope) do
          res = MilestoneRepositoryEcto.create_milestone(attrs)
          maybe_create_project_events(res, nil, scope)
          res
        else
          {:error, :unauthorized}
        end
    end
  end

  defp maybe_create_project_events({:error, _}, _attrs, _scope) do
    :ok
  end

  defp maybe_create_project_events({:ok, milestone}, attrs, scope) do
    MilestoneUpdateStatus.generate_events(milestone, attrs, scope)
    |> Enum.each(fn event ->
      ProjectEventsRepositoryEcto.create_event(event)
    end)

    :ok
  end
end
