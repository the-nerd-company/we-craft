defmodule WeCraft.Milestones.UseCases.DeleteTaskUseCase do
  @moduledoc """
  Use case for deleting a task with proper authorization.
  """

  alias WeCraft.Milestones.Infrastructure.Ecto.TaskRepositoryEcto
  alias WeCraft.Milestones.TaskPermissions

  def delete_task(%{task_id: task_id, scope: scope}) do
    case TaskRepositoryEcto.get_task(task_id) do
      {:error, :not_found} ->
        {:error, :not_found}

      {:ok, task} ->
        if TaskPermissions.can_delete_task?(task, scope) do
          TaskRepositoryEcto.delete_task(task)
        else
          {:error, :unauthorized}
        end
    end
  end
end
