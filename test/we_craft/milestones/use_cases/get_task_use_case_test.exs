defmodule WeCraft.Milestones.UseCases.GetTaskUseCaseTest do
  @moduledoc """
  Tests for the GetTaskUseCase.
  """
  use WeCraft.DataCase, async: true

  alias WeCraft.Milestones

  import WeCraft.MilestonesFixtures
  import WeCraft.AccountsFixtures
  import WeCraft.ProjectsFixtures

  setup do
    owner = user_fixture()
    other_user = user_fixture()
    project = project_fixture(%{owner: owner})
    milestone = milestone_fixture(%{project: project})
    task = task_fixture(%{milestone: milestone})

    %{
      task: task,
      owner_scope: %{user: owner},
      other_user_scope: %{user: other_user}
    }
  end

  describe "get_task/1 with scope (authorized)" do
    test "returns the task for an authorized user", %{
      task: task,
      owner_scope: owner_scope
    } do
      assert {:ok, result_task} = Milestones.get_task(%{task_id: task.id, scope: owner_scope})
      assert result_task.id == task.id
    end

    test "returns unauthorized for a user without permission", %{
      task: task,
      other_user_scope: other_user_scope
    } do
      assert {:error, :unauthorized} =
               Milestones.get_task(%{task_id: task.id, scope: other_user_scope})
    end

    test "returns ok with nil for a non-existent task", %{owner_scope: owner_scope} do
      assert {:ok, nil} =
               Milestones.get_task(%{task_id: -1, scope: owner_scope})
    end
  end
end
