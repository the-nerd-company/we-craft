defmodule WeCraft.Milestones.UseCases.UpdateTaskUseCaseTest do
  @moduledoc """
  Tests for the UpdateTaskUseCase.
  """
  use WeCraft.DataCase, async: true

  alias WeCraft.Milestones
  alias WeCraft.Milestones.Infrastructure.Ecto.TaskRepositoryEcto

  import WeCraft.AccountsFixtures
  import WeCraft.ProjectsFixtures
  import WeCraft.MilestonesFixtures

  setup do
    owner = user_fixture()
    other_user = user_fixture()
    project = project_fixture(%{owner: owner})
    milestone = milestone_fixture(%{project: project})
    task = task_fixture(%{milestone: milestone})

    %{
      owner: owner,
      other_user: other_user,
      project: project,
      milestone: milestone,
      task: task,
      owner_scope: %{user: owner},
      other_user_scope: %{user: other_user}
    }
  end

  describe "update_task/1 with scope (authorized)" do
    test "updates a task with valid data and authorization", %{
      task: task,
      owner_scope: owner_scope
    } do
      assert {:ok, _} =
               Milestones.update_task(%{
                 task_id: task.id,
                 attrs: %{title: "Updated Task"},
                 scope: owner_scope
               })

      assert {:ok, updated_task} = TaskRepositoryEcto.get_task(task.id)
      assert updated_task.id == task.id
      assert updated_task.title == "Updated Task"
    end

    test "returns unauthorized error for user without permission", %{
      task: task,
      other_user_scope: other_user_scope
    } do
      assert {:error, :unauthorized} =
               Milestones.update_task(%{task_id: task.id, attrs: %{}, scope: other_user_scope})
    end

    test "returns not_found for a non-existent task", %{owner_scope: owner_scope} do
      assert {:error, :not_found} =
               Milestones.update_task(%{task_id: -2, attrs: %{}, scope: owner_scope})
    end
  end
end
