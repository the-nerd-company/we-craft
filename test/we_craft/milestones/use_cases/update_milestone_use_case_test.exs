defmodule WeCraft.Milestones.UseCases.UpdateMilestoneUseCaseTest do
  @moduledoc """
  Tests for the UpdateMilestoneUseCase.
  """
  use WeCraft.DataCase, async: true

  alias WeCraft.Milestones
  alias WeCraft.Projects.Infrastructure.Ecto.ProjectEventsRepositoryEcto

  describe "update_milestone/1" do
    test "updates milestone with valid attributes and permissions" do
      user = WeCraft.AccountsFixtures.user_fixture()
      scope = WeCraft.AccountsFixtures.user_scope_fixture(user)
      project = WeCraft.ProjectsFixtures.project_fixture(%{owner: user})

      attrs = %{
        title: "Original Title",
        description: "Original Description",
        status: "planned",
        project_id: project.id
      }

      {:ok, milestone} = Milestones.create_milestone(%{attrs: attrs, scope: scope})

      update_attrs = %{
        title: "Updated Title",
        description: "Updated Description",
        status: "active"
      }

      assert {:ok, updated_milestone} =
               Milestones.update_milestone(%{
                 milestone_id: milestone.id,
                 attrs: update_attrs,
                 scope: scope
               })

      assert updated_milestone.title == "Updated Title"
      assert updated_milestone.description == "Updated Description"
      assert updated_milestone.status == :active
      assert updated_milestone.id == milestone.id

      [event] = ProjectEventsRepositoryEcto.get_events_for_project(project.id)
      assert event.event_type == "milestone_active"
      assert event.project_id == project.id

      assert event.metadata == %{
               "milestone_id" => milestone.id,
               "milestone_title" => milestone.title,
               "user_id" => scope.user.id
             }
    end

    test "complete milestone with valid attributes and permissions create a project event" do
      user = WeCraft.AccountsFixtures.user_fixture()
      scope = WeCraft.AccountsFixtures.user_scope_fixture(user)
      project = WeCraft.ProjectsFixtures.project_fixture(%{owner: user})

      attrs = %{
        title: "Original Title",
        description: "Original Description",
        status: "planned",
        project_id: project.id
      }

      {:ok, milestone} = Milestones.create_milestone(%{attrs: attrs, scope: scope})

      update_attrs = %{
        title: "Updated Title",
        description: "Updated Description",
        status: "completed"
      }

      assert {:ok, updated_milestone} =
               Milestones.update_milestone(%{
                 milestone_id: milestone.id,
                 attrs: update_attrs,
                 scope: scope
               })

      assert updated_milestone.title == "Updated Title"
      assert updated_milestone.description == "Updated Description"
      assert updated_milestone.status == :completed
      assert updated_milestone.id == milestone.id

      [event] = ProjectEventsRepositoryEcto.get_events_for_project(project.id)
      assert event.event_type == "milestone_completed"
      assert event.project_id == project.id

      assert event.metadata == %{
               "milestone_id" => milestone.id,
               "milestone_title" => milestone.title,
               "user_id" => scope.user.id
             }
    end

    test "returns error with invalid attributes" do
      user = WeCraft.AccountsFixtures.user_fixture()
      scope = WeCraft.AccountsFixtures.user_scope_fixture(user)
      project = WeCraft.ProjectsFixtures.project_fixture(%{owner: user})

      attrs = %{
        title: "Original Title",
        description: "Original Description",
        status: "planned",
        project_id: project.id
      }

      {:ok, milestone} = WeCraft.Milestones.create_milestone(%{attrs: attrs, scope: scope})

      update_attrs = %{title: "", description: ""}

      assert {:error, %Ecto.Changeset{} = changeset} =
               Milestones.update_milestone(%{
                 milestone_id: milestone.id,
                 attrs: update_attrs,
                 scope: scope
               })

      assert errors_on(changeset) == %{
               title: ["can't be blank"],
               description: ["can't be blank"]
             }
    end

    test "returns error when user doesn't have permission" do
      user = WeCraft.AccountsFixtures.user_fixture()
      other_user = WeCraft.AccountsFixtures.user_fixture()
      scope = WeCraft.AccountsFixtures.user_scope_fixture(user)
      project = WeCraft.ProjectsFixtures.project_fixture(%{owner: other_user})

      attrs = %{
        title: "Title",
        description: "Description",
        status: "planned",
        project_id: project.id
      }

      other_scope = WeCraft.AccountsFixtures.user_scope_fixture(other_user)
      {:ok, milestone} = Milestones.create_milestone(%{attrs: attrs, scope: other_scope})

      update_attrs = %{title: "Updated Title"}

      assert {:error, :unauthorized} =
               Milestones.update_milestone(%{
                 milestone_id: milestone.id,
                 attrs: update_attrs,
                 scope: scope
               })
    end

    test "returns error when milestone doesn't exist" do
      user = WeCraft.AccountsFixtures.user_fixture()
      scope = WeCraft.AccountsFixtures.user_scope_fixture(user)

      update_attrs = %{title: "Updated Title"}

      assert {:error, :not_found} =
               Milestones.update_milestone(%{
                 milestone_id: 99_999,
                 attrs: update_attrs,
                 scope: scope
               })
    end
  end
end
