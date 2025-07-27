defmodule WeCraft.Milestones.UseCases.DeleteTaskUseCaseTest do
  @moduledoc """
  Tests for the CreateTaskUseCase.
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

  describe "delete_task/1 with scope (authorized)" do
    test "deletes a task with valid data and authorization", %{
      task: task,
      owner_scope: owner_scope
    } do
      assert {:ok, _} = Milestones.delete_task(%{task_id: task.id, scope: owner_scope})
      assert {:error, :not_found} = TaskRepositoryEcto.get_task(task.id)
    end

    test "returns unauthorized error for user without permission", %{
      task: task,
      other_user_scope: other_user_scope
    } do
      assert {:error, :unauthorized} =
               Milestones.delete_task(%{task_id: task.id, scope: other_user_scope})

      assert {:ok, _} = TaskRepositoryEcto.get_task(task.id)
    end

    test "returns not_found for a non-existent task", %{owner_scope: owner_scope} do
      assert {:error, :not_found} =
               Milestones.delete_task(%{task_id: -2, scope: owner_scope})
    end
  end
end
