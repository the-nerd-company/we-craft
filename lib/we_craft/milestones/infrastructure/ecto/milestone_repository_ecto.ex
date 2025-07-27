defmodule WeCraft.Milestones.Infrastructure.Ecto.MilestoneRepositoryEcto do
  @moduledoc """
  Ecto-based implementation of the MilestoneRepository.
  This module interacts with the database to manage project milestones.
  """
  alias WeCraft.Milestones.Milestone
  alias WeCraft.Repo
  import Ecto.Query

  def create_milestone(attrs) do
    %Milestone{}
    |> Milestone.changeset(attrs)
    |> Repo.insert()
  end

  def update_milestone(%Milestone{} = milestone, attrs) do
    milestone
    |> Milestone.changeset(attrs)
    |> Repo.update()
  end

  def get_milestone!(id) do
    Repo.get!(Milestone, id)
  end

  def get_milestone(id) do
    case Repo.get(Milestone, id) |> Repo.preload(:tasks) do
      nil -> {:error, :not_found}
      milestone -> {:ok, milestone}
    end
  end

  def get_milestone_with_project(id) do
    case Repo.get(Milestone, id) |> Repo.preload(:project) do
      nil -> {:error, :not_found}
      milestone -> {:ok, milestone}
    end
  end

  def list_project_milestones(project_id) do
    milestones =
      from(m in Milestone,
        where: m.project_id == ^project_id,
        order_by: [asc: m.due_date, asc: m.inserted_at],
        preload: [:tasks]
      )
      |> Repo.all()

    {:ok, milestones}
  end

  def delete_milestone(%Milestone{} = milestone) do
    Repo.delete(milestone)
  end
end
