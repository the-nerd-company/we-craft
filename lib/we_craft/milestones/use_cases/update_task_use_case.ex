defmodule WeCraft.Milestones.UseCases.UpdateTaskUseCase do
  @moduledoc """
  Use case for updating a task with proper authorization.
  """

  alias WeCraft.Milestones.Infrastructure.Ecto.TaskRepositoryEcto
  alias WeCraft.Milestones.TaskPermissions

  def update_task(%{task_id: task_id, attrs: attrs, scope: scope}) do
    case TaskRepositoryEcto.get_task(task_id) do
      {:error, :not_found} ->
        {:error, :not_found}

      {:ok, task} ->
        if TaskPermissions.can_update_task?(task, scope) do
          TaskRepositoryEcto.update_task(task, attrs)
        else
          {:error, :unauthorized}
        end
    end
  end
end
