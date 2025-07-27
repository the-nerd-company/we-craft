defmodule WeCraft.Milestones.Task do
  @moduledoc """
  Represents a task within a milestone in the WeCraft application.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias WeCraft.Milestones.Milestone

  @status [:planned, :active, :completed]

  def all_status, do: @status

  schema "tasks" do
    field :title, :string
    field :description, :string
    field :status, Ecto.Enum, values: @status
    belongs_to :milestone, Milestone

    timestamps()
  end

  def changeset(task, attrs) do
    task
    |> cast(attrs, [:title, :description, :status, :milestone_id])
    |> validate_required([:title, :description, :status, :milestone_id])
  end
end
