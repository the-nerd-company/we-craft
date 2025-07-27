defmodule WeCraft.Milestones.UseCases.CreateTaskUseCaseTest do
  @moduledoc """
  Tests for the CreateTaskUseCase.
  """
  use WeCraft.DataCase, async: true

  alias WeCraft.AccountsFixtures
  alias WeCraft.Milestones
  alias WeCraft.Milestones.Task
  alias WeCraft.MilestonesFixtures
  alias WeCraft.ProjectsFixtures

  setup do
    owner = AccountsFixtures.user_fixture()
    other_user = AccountsFixtures.user_fixture()
    project = ProjectsFixtures.project_fixture(%{owner: owner})
    milestone = MilestonesFixtures.milestone_fixture(%{project: project})

    %{
      owner: owner,
      other_user: other_user,
      project: project,
      milestone: milestone,
      owner_scope: %{user: owner},
      other_user_scope: %{user: other_user}
    }
  end

  describe "create_task/1 with scope (authorized)" do
    test "creates a task with valid data and authorization", %{
      milestone: milestone,
      owner_scope: owner_scope
    } do
      attrs = %{
        title: "New Task",
        description: "A great task",
        status: :active,
        milestone_id: milestone.id
      }

      assert {:ok, %Task{} = task} =
               Milestones.create_task(%{attrs: attrs, scope: owner_scope})

      assert task.title == "New Task"
      assert task.milestone_id == milestone.id
    end

    test "returns unauthorized error for user without permission", %{
      milestone: milestone,
      other_user_scope: other_user_scope
    } do
      attrs = %{
        title: "Unauthorized Task",
        milestone_id: milestone.id
      }

      assert {:error, :unauthorized} =
               Milestones.create_task(%{attrs: attrs, scope: other_user_scope})
    end

    test "returns milestone_not_found for a non-existent milestone", %{
      owner_scope: owner_scope
    } do
      attrs = %{
        title: "Task for Ghost Milestone",
        description: "This milestone does not exist",
        milestone_id: -4
      }

      assert {:error, :milestone_not_found} =
               Milestones.create_task(%{attrs: attrs, scope: owner_scope})
    end
  end
end
