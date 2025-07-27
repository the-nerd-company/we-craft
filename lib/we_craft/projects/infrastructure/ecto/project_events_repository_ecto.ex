defmodule WeCraft.Projects.Infrastructure.Ecto.ProjectEventsRepositoryEcto do
  @moduledoc """
  Ecto-based repository for managing project events in the WeCraft application.
  This module provides functions to create and retrieve project events.
  """

  import Ecto.Query, warn: false

  alias WeCraft.Projects.ProjectEvent
  alias WeCraft.Repo

  def create_event(attrs) do
    %ProjectEvent{}
    |> ProjectEvent.changeset(attrs)
    |> Repo.insert()
  end

  def get_events_for_project(project_id) do
    Repo.all(from e in ProjectEvent, where: e.project_id == ^project_id)
  end

  def get_last_events(%{limit: limit}) do
    Repo.all(
      from e in ProjectEvent,
        order_by: [desc: e.inserted_at],
        limit: ^limit
    )
    |> Repo.preload(:project)
  end
end
