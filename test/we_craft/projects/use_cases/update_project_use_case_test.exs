defmodule WeCraft.Projects.UseCases.UpdateProjectUseCaseTest do
  @moduledoc """
  Tests for the UpdateProjectUseCase module.
  """
  use WeCraft.DataCase, async: true

  import Ecto.Query

  alias WeCraft.Projects.Infrastructure.Ecto.ProjectEventsRepositoryEcto
  alias WeCraft.Projects.ProjectEvent
  alias WeCraft.Projects.UseCases.UpdateProjectUseCase
  alias WeCraft.ProjectsFixtures
  alias WeCraft.Repo

  describe "update_project/1" do
    setup do
      # Setup - create initial project
      project = ProjectsFixtures.project_fixture()

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
               UpdateProjectUseCase.update_project(%{
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
               UpdateProjectUseCase.update_project(%{
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
               UpdateProjectUseCase.update_project(%{
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
               UpdateProjectUseCase.update_project(%{
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
               UpdateProjectUseCase.update_project(%{
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
end
