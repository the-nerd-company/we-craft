defmodule WeCraft.Accounts.Infrastructure.Ecto.TaskRepositoryEcto do
  @moduledoc """
  Provides Ecto-based repository functions for managing tasks in the WeCraft application.
  This module interacts with the database to perform CRUD operations on Milestones.
  """
  alias WeCraft.Milestones.Task
  alias WeCraft.Repo

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

  def delete_task(%Task{} = task) do
    Repo.delete(task)
  end

  def get_task!(id) do
    Repo.get!(Task, id)
  end

  def list_tasks do
    Repo.all(Task)
  end
end
