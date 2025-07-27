defmodule WeCraft.Projects.UseCases.UpdateProjectUseCaseTest do
  @moduledoc """
  Tests for the UpdateProjectUseCase module.
  """
  use WeCraft.DataCase, async: true

  import Ecto.Query
  import WeCraft.ProjectsFixtures

  alias WeCraft.Projects
  alias WeCraft.Projects.Infrastructure.Ecto.ProjectEventsRepositoryEcto
  alias WeCraft.Projects.ProjectEvent
  alias WeCraft.Repo

  describe "update_project/1" do
    setup do
      # Setup - create initial project
      project = project_fixture()

      # Clear any events that might have been created by fixture
      Repo.delete_all(from e in ProjectEvent, where: e.project_id == ^project.id)

      %{project: project}
    end

    test "updates a project with valid attributes", %{project: project} do
      # Update attributes
      attrs = %{
        "title" => "Updated Project Title",
        "description" => "Updated project description"
      }

      # Execute update
      assert {:ok, updated_project} =
               Projects.update_project(%{
                 project: project,
                 attrs: attrs
               })

      # Assert project was updated correctly
      assert updated_project.id == project.id
      assert updated_project.title == "Updated Project Title"
      assert updated_project.description == "Updated project description"

      # Assert no events were created (since neither status nor visibility changed)
      events = ProjectEventsRepositoryEcto.get_events_for_project(project.id)
      assert Enum.empty?(events)
    end

    test "updates project status and creates status update event", %{project: project} do
      # Ensure project has idea status
      {:ok, project} = Repo.update(Ecto.Changeset.change(project, status: :idea))

      # Update status to in_dev
      attrs = %{"status" => "in_dev"}

      # Execute update
      assert {:ok, updated_project} =
               Projects.update_project(%{
                 project: project,
                 attrs: attrs
               })

      # Assert project was updated correctly
      assert updated_project.id == project.id
      assert updated_project.status == :in_dev

      # Assert status update event was created
      events = ProjectEventsRepositoryEcto.get_events_for_project(project.id)
      assert length(events) == 1

      [event] = events
      assert event.event_type == "project_status_updated"
      assert event.project_id == project.id
    end

    test "updates status from in_dev to live", %{project: project} do
      # Update project to have in_dev status first
      {:ok, project} = Repo.update(Ecto.Changeset.change(project, status: :in_dev))

      # Update status to live
      attrs = %{"status" => "live"}

      # Execute update
      assert {:ok, updated_project} =
               Projects.update_project(%{
                 project: project,
                 attrs: attrs
               })

      # Assert project was updated correctly
      assert updated_project.id == project.id
      assert updated_project.status == :live

      # Assert status update event was created
      events = ProjectEventsRepositoryEcto.get_events_for_project(project.id)
      assert length(events) == 1

      [event] = events
      assert event.event_type == "project_status_updated"
      assert event.project_id == project.id
    end

    test "doesn't create events when updating non-event fields", %{project: project} do
      # Update non-event fields
      attrs = %{
        "title" => "New Title",
        "description" => "New description",
        "tags" => ["elixir", "phoenix"]
      }

      # Execute update
      assert {:ok, updated_project} =
               Projects.update_project(%{
                 project: project,
                 attrs: attrs
               })

      # Assert project was updated correctly
      assert updated_project.id == project.id
      assert updated_project.title == "New Title"

      # Assert no events were created
      events = ProjectEventsRepositoryEcto.get_events_for_project(project.id)
      assert Enum.empty?(events)
    end

    test "handles multiple project updates in one call", %{project: project} do
      # Ensure project has idea status
      {:ok, project} = Repo.update(Ecto.Changeset.change(project, status: :idea))

      # Update multiple fields including status
      attrs = %{
        "title" => "New Title",
        "description" => "New description",
        "status" => "in_dev"
      }

      # Execute update
      assert {:ok, updated_project} =
               Projects.update_project(%{
                 project: project,
                 attrs: attrs
               })

      # Assert project was updated correctly
      assert updated_project.id == project.id
      assert updated_project.title == "New Title"
      assert updated_project.description == "New description"
      assert updated_project.status == :in_dev

      # Assert status event was created
      events = ProjectEventsRepositoryEcto.get_events_for_project(project.id)
      assert length(events) == 1

      [event] = events
      assert event.event_type == "project_status_updated"
      assert event.project_id == project.id
    end
  end

  test "status update currently produces no events (documents existing behavior)" do
    project = project_fixture(%{status: :idea})

    {:ok, updated} =
      Projects.update_project(%{project: project, attrs: %{"status" => :in_dev}})

    assert updated.status == :in_dev
    events = ProjectEventsRepositoryEcto.get_last_events(%{limit: 3})
    refute Enum.any?(events, &(&1.event_type == "project_status_updated"))
  end

  test "no change produces no events" do
    project = project_fixture(%{status: :idea})

    {:ok, _} =
      Projects.update_project(%{project: project, attrs: %{"name" => project.title}})

    events = ProjectEventsRepositoryEcto.get_last_events(%{limit: 2})

    refute Enum.any?(
             events,
             &(&1.event_type in ["project_status_updated", "project_visibility_updated"])
           )
  end
end
