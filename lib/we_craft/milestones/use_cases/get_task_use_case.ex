defmodule WeCraft.Milestones.UseCases.GetTaskUseCase do
  @moduledoc """
  Use case for getting a single task with proper authorization.
  """

  alias WeCraft.Milestones.Infrastructure.Ecto.TaskRepositoryEcto
  alias WeCraft.Milestones.TaskPermissions

  def get_task(%{task_id: task_id, scope: scope}) do
    case TaskRepositoryEcto.get_task(task_id) do
      {:error, :not_found} ->
        {:ok, nil}

      {:ok, task} ->
        if TaskPermissions.can_view_task?(task, scope) do
          {:ok, task}
        else
          {:error, :unauthorized}
        end
    end
  end
end
