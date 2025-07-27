defmodule WeCraft.Milestones.UseCases.CreateMilestoneUseCaseTest do
  @moduledoc """
  Tests for the CreateMilestoneUseCase.
  """
  use WeCraft.DataCase, async: true

  alias WeCraft.Milestones
  alias WeCraft.Milestones.Milestone
  alias WeCraft.Projects.Infrastructure.Ecto.ProjectEventsRepositoryEcto

  import WeCraft.AccountsFixtures
  import WeCraft.ProjectsFixtures

  describe "create_milestone/1" do
    test "creates milestone with valid attributes and permissions" do
      user = user_fixture()
      scope = user_scope_fixture(user)
      project = project_fixture(%{owner: user})

      attrs = %{
        title: "Test Milestone",
        description: "A test milestone description",
        status: "active",
        project_id: project.id
      }

      assert {:ok, %Milestone{} = milestone} =
               Milestones.create_milestone(%{
                 attrs: attrs,
                 scope: scope
               })

      assert milestone.title == "Test Milestone"
      assert milestone.description == "A test milestone description"
      assert milestone.status == :active
      assert milestone.project_id == project.id

      [event] = ProjectEventsRepositoryEcto.get_events_for_project(project.id)

      assert event.event_type == "milestone_active"
      assert event.metadata["milestone_id"] == milestone.id
      assert event.metadata["milestone_title"] == milestone.title
      assert event.metadata["user_id"] == user.id
    end

    test "returns error with invalid attributes" do
      user = user_fixture()
      scope = user_scope_fixture(user)

      attrs = %{
        title: "",
        description: "",
        status: nil,
        project_id: nil
      }

      assert {:error, %Ecto.Changeset{} = changeset} =
               Milestones.create_milestone(%{
                 attrs: attrs,
                 scope: scope
               })

      assert errors_on(changeset) == %{
               title: ["can't be blank"],
               description: ["can't be blank"],
               status: ["can't be blank"],
               project_id: ["can't be blank"]
             }
    end

    test "returns error when user doesn't have permission" do
      user = user_fixture()
      other_user = user_fixture()
      scope = user_scope_fixture(user)
      project = project_fixture(%{owner: other_user})

      attrs = %{
        title: "Test Milestone",
        description: "A test milestone description",
        status: "planned",
        project_id: project.id
      }

      assert {:error, :unauthorized} =
               Milestones.create_milestone(%{
                 attrs: attrs,
                 scope: scope
               })
    end

    test "returns error when project doesn't exist" do
      user = user_fixture()
      scope = user_scope_fixture(user)

      attrs = %{
        title: "Test Milestone",
        description: "A test milestone description",
        status: "planned",
        project_id: 99_999
      }

      assert {:error, :project_not_found} =
               Milestones.create_milestone(%{
                 attrs: attrs,
                 scope: scope
               })
    end
  end
end
