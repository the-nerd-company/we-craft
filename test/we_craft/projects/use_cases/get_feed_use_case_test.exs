defmodule WeCraft.Projects.UseCases.GetFeedUseCaseTest do
  @moduledoc """
  Tests for the GetFeedUseCase.
  """
  use WeCraft.DataCase, async: true

  alias WeCraft.Projects.Infrastructure.Ecto.ProjectEventsRepositoryEcto
  alias WeCraft.Projects.UseCases.GetFeedUseCase
  alias WeCraft.ProjectsFixtures

  describe "get_feed/1" do
    test "returns the last N events with project preloaded ordered by inserted_at desc" do
      project = ProjectsFixtures.project_fixture()

      event_types = ["project_created", "project_updated", "member_added"]

      for type <- event_types do
        {:ok, _} =
          ProjectEventsRepositoryEcto.create_event(%{
            event_type: type,
            project_id: project.id
          })
      end

      limit = 2
      assert {:ok, events} = GetFeedUseCase.get_feed(%{limit: limit})
      assert length(events) == limit

      # Ensure order desc by inserted_at
      assert Enum.sort_by(events, & &1.inserted_at, :desc) == events

      # Ensure project preloaded
      for event <- events do
        assert event.project
        assert event.project.id == project.id
        assert event.event_type in event_types
      end
    end

    test "returns empty list when there are no events" do
      assert {:ok, events} = GetFeedUseCase.get_feed(%{limit: 5})
      assert events == []
    end

    test "returns empty list when limit is zero" do
      # Create one event to ensure limit actually filters
      project = ProjectsFixtures.project_fixture()

      {:ok, _} =
        ProjectEventsRepositoryEcto.create_event(%{
          event_type: "project_created",
          project_id: project.id
        })

      assert {:ok, events} = GetFeedUseCase.get_feed(%{limit: 0})
      assert events == []
    end
  end
end
