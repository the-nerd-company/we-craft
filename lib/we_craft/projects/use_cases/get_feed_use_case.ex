defmodule WeCraft.Projects.UseCases.GetFeedUseCase do
  @moduledoc """
  Use case for retrieving the feed of project events.
  This module provides functions to get the latest project events.
  """

  alias WeCraft.Projects.Infrastructure.Ecto.ProjectEventsRepositoryEcto

  def get_feed(%{limit: limit}) do
    {:ok, ProjectEventsRepositoryEcto.get_last_events(%{limit: limit})}
  end
end
