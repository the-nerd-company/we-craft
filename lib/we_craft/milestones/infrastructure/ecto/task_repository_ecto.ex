defmodule WeCraft.Milestones.Infrastructure.Ecto.TaskRepositoryEcto do
  @moduledoc """
  Ecto-based implementation of the TaskRepository.
  This module interacts with the database to manage milestone Milestones.
  """
  alias WeCraft.Milestones.Task
  alias WeCraft.Repo
  import Ecto.Query

  def create_task(attrs) do
    %Task{}
    |> Task.changeset(attrs)
    |> Repo.insert()
  end

  def update_task(%Task{} = task, attrs) do
    task
    |> Task.changeset(attrs)
    |> Repo.update()
  end

  def get_task!(id) do
    Repo.get!(Task, id)
  end

  def get_task(id) do
    case Repo.get(Task, id) do
      nil -> {:error, :not_found}
      task -> {:ok, task}
    end
  end

  def get_task_with_milestone(id) do
    case Repo.get(Task, id) |> Repo.preload(:milestone) do
      nil -> {:error, :not_found}
      task -> {:ok, task}
    end
  end

  def list_milestone_tasks(milestone_id) do
    tasks =
      from(t in Task,
        where: t.milestone_id == ^milestone_id,
        order_by: [asc: t.inserted_at]
      )
      |> Repo.all()

    {:ok, tasks}
  end

  def delete_task(%Task{} = task) do
    Repo.delete(task)
  end
end
