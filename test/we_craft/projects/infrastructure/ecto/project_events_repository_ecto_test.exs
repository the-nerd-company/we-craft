defmodule WeCraft.Projects.Infrastructure.Ecto.ProjectEventsRepositoryEctoTest do
  @moduledoc """
  Tests for the ProjectEventsRepositoryEcto module.
  """
  use WeCraft.DataCase, async: true

  alias WeCraft.Projects.Infrastructure.Ecto.ProjectEventsRepositoryEcto
  alias WeCraft.Projects.ProjectEvent
  alias WeCraft.ProjectsFixtures

  describe "create_event/1" do
    test "successfully creates a project event with valid attributes" do
      # Create a project first
      project = ProjectsFixtures.project_fixture()

      # Define valid event attributes
      attrs = %{
        event_type: "project_created",
        project_id: project.id
      }

      # Create the event
      assert {:ok, %ProjectEvent{} = event} = ProjectEventsRepositoryEcto.create_event(attrs)
      assert event.event_type == "project_created"
      assert event.project_id == project.id
    end

    test "returns error with invalid attributes" do
      # Test missing event_type
      attrs = %{project_id: Ecto.UUID.generate()}
      assert {:error, changeset} = ProjectEventsRepositoryEcto.create_event(attrs)
      assert %{event_type: ["can't be blank"]} = errors_on(changeset)

      # Test missing project_id
      attrs = %{event_type: "project_created"}
      assert {:error, changeset} = ProjectEventsRepositoryEcto.create_event(attrs)
      assert %{project_id: ["can't be blank"]} = errors_on(changeset)
    end
  end

  describe "get_events_for_project/1" do
    test "returns all events for a given project" do
      # Create a project
      project = ProjectsFixtures.project_fixture()

      # Create multiple events for the project
      event_types = ["project_created", "project_updated", "member_added"]

      for event_type <- event_types do
        {:ok, _} =
          ProjectEventsRepositoryEcto.create_event(%{
            event_type: event_type,
            project_id: project.id
          })
      end

      # Create another project with an event to ensure we only get events for the correct project
      other_project = ProjectsFixtures.project_fixture()

      {:ok, _} =
        ProjectEventsRepositoryEcto.create_event(%{
          event_type: "project_created",
          project_id: other_project.id
        })

      # Fetch events for the original project
      events = ProjectEventsRepositoryEcto.get_events_for_project(project.id)

      # Verify we got the right number of events and they belong to our project
      assert length(events) == 3

      for event <- events do
        assert event.project_id == project.id
        assert event.event_type in event_types
      end

      # Verify events for the other project are separate
      other_events = ProjectEventsRepositoryEcto.get_events_for_project(other_project.id)
      assert length(other_events) == 1
      [other_event] = other_events
      assert other_event.project_id == other_project.id
      assert other_event.event_type == "project_created"
    end

    test "returns empty list when no events exist for a project" do
      # Create a project with no events
      project = ProjectsFixtures.project_fixture()

      # Fetch events for the project
      events = ProjectEventsRepositoryEcto.get_events_for_project(project.id)

      # Verify we got an empty list
      assert events == []
    end

    test "returns empty list for non-existent project ID" do
      # Use a non-existent integer ID that doesn't match any project
      non_existent_id = 999_999_999

      # Fetch events for the non-existent project
      events = ProjectEventsRepositoryEcto.get_events_for_project(non_existent_id)

      # Verify we got an empty list
      assert events == []
    end
  end

  describe "get_last_events/1" do
    test "returns the last N events ordered by inserted_at" do
      # Create a project
      project = ProjectsFixtures.project_fixture()

      # Create multiple events for the project
      event_types = ["project_created", "project_updated", "member_added"]

      for event_type <- event_types do
        {:ok, _} =
          ProjectEventsRepositoryEcto.create_event(%{
            event_type: event_type,
            project_id: project.id
          })
      end

      # Fetch the last 2 events
      limit = 2
      events = ProjectEventsRepositoryEcto.get_last_events(%{limit: limit})

      # Verify we got the right number of events and they are ordered by inserted_at
      assert length(events) == limit

      # Check that the events are ordered correctly
      assert Enum.sort_by(events, & &1.inserted_at, :desc) == events
    end

    test "returns an empty list when no events exist" do
      # Fetch the last 5 events when no events exist
      limit = 5
      events = ProjectEventsRepositoryEcto.get_last_events(%{limit: limit})

      # Verify we got an empty list
      assert events == []
    end

    test "returns empty list for zero limit" do
      # Fetch last 0 events
      limit = 0
      events = ProjectEventsRepositoryEcto.get_last_events(%{limit: limit})

      # Verify we got an empty list
      assert events == []
    end
  end
end
