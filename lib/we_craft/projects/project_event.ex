defmodule WeCraft.Projects.ProjectEvent do
  @moduledoc """
  Represents an event related to a project, such as creation or updates.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "project_events" do
    field :event_type, :string
    field :metadata, :map
    belongs_to :project, WeCraft.Projects.Project

    timestamps()
  end

  @doc false
  def changeset(project_event, attrs) do
    project_event
    |> cast(attrs, [:event_type, :project_id, :metadata])
    |> validate_required([:event_type, :project_id])
  end
end
