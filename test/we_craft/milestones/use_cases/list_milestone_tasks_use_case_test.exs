defmodule WeCraft.Milestones.UseCases.ListMilestoneTasksUseCaseTest do
  use WeCraft.DataCase, async: true

  alias WeCraft.Milestones

  import WeCraft.AccountsFixtures
  import WeCraft.ProjectsFixtures
  import WeCraft.MilestonesFixtures

  @moduledoc """
  Tests for the ListMilestoneTasksUseCase.
  """

  setup do
    owner = user_fixture()
    other_user = user_fixture()
    project = project_fixture(%{owner: owner})
    milestone = milestone_fixture(%{project: project})

    task_fixture(%{milestone: milestone, title: "Task 1"})
    task_fixture(%{milestone: milestone, title: "Task 2"})

    %{
      milestone: milestone,
      owner_scope: %{user: owner},
      other_user_scope: %{user: other_user}
    }
  end

  describe "list_milestone_tasks/1 with scope (authorized)" do
    test "returns the list of tasks for an authorized user", %{
      milestone: milestone,
      owner_scope: owner_scope
    } do
      assert {:ok, tasks} =
               Milestones.list_milestone_tasks(%{
                 milestone_id: milestone.id,
                 scope: owner_scope
               })

      assert length(tasks) == 2
    end

    test "returns unauthorized for a user without permission", %{
      milestone: milestone,
      other_user_scope: other_user_scope
    } do
      assert {:error, :unauthorized} =
               Milestones.list_milestone_tasks(%{
                 milestone_id: milestone.id,
                 scope: other_user_scope
               })
    end

    test "returns milestone_not_found for a non-existent milestone", %{owner_scope: owner_scope} do
      assert {:error, :milestone_not_found} =
               Milestones.list_milestone_tasks(%{
                 milestone_id: -1,
                 scope: owner_scope
               })
    end
  end
end
