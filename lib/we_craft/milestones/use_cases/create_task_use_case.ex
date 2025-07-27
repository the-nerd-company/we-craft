defmodule WeCraft.Milestones.UseCases.CreateTaskUseCase do
  @moduledoc """
  Use case for creating a task with proper authorization.
  """

  alias WeCraft.Milestones.Infrastructure.Ecto.MilestoneRepositoryEcto
  alias WeCraft.Milestones.Infrastructure.Ecto.TaskRepositoryEcto
  alias WeCraft.Milestones.TaskPermissions

  def create_task(%{attrs: attrs, scope: scope}) do
    milestone_id = attrs[:milestone_id] || attrs["milestone_id"]

    case MilestoneRepositoryEcto.get_milestone_with_project(milestone_id) do
      {:error, :not_found} ->
        {:error, :milestone_not_found}

      {:ok, milestone} ->
        if TaskPermissions.can_create_task?(milestone, scope) do
          TaskRepositoryEcto.create_task(attrs)
        else
          {:error, :unauthorized}
        end
    end
  end
end
