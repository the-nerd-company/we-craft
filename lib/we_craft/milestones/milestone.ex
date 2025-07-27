defmodule WeCraft.Milestones.Milestone do
  @moduledoc """
  Represents a milestone in the WeCraft application.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias WeCraft.Milestones.Task
  alias WeCraft.Projects.Project

  @status [:planned, :active, :completed]

  def all_status, do: @status

  schema "milestones" do
    field :title, :string
    field :description, :string
    field :due_date, :utc_datetime
    field :completed_at, :utc_datetime
    field :status, Ecto.Enum, values: @status

    belongs_to :project, Project
    has_many :tasks, Task

    timestamps()
  end

  @doc false
  def changeset(milestone, attrs) do
    milestone
    |> cast(attrs, [:title, :description, :due_date, :completed_at, :project_id, :status])
    |> validate_required([:title, :description, :status, :project_id])
  end
end
