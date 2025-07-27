defmodule WeCraft.Accounts.Infrastructure.Ecto.TaskRepositoryEctoTest do
  @moduledoc """
  Tests for the TaskRepositoryEcto module.
  """
  use WeCraft.DataCase, async: true

  alias WeCraft.Accounts.Infrastructure.Ecto.TaskRepositoryEcto
  alias WeCraft.Milestones.Task

  import WeCraft.MilestonesFixtures

  describe "create_task/1" do
    test "creates a task with valid attributes" do
      milestone = milestone_fixture()

      attrs = %{
        title: "Test Task",
        description: "Test Description",
        status: :planned,
        milestone_id: milestone.id
      }

      assert {:ok, %Task{} = task} = TaskRepositoryEcto.create_task(attrs)
      assert task.title == "Test Task"
      assert task.description == "Test Description"
      assert task.status == :planned
    end

    test "returns error changeset with invalid attributes" do
      attrs = %{title: nil, description: "Test Description", status: :planned, milestone_id: nil}
      assert {:error, %Ecto.Changeset{} = changeset} = TaskRepositoryEcto.create_task(attrs)
      assert changeset.valid? == false
    end
  end

  describe "update_task/1" do
    test "updates a task with valid attributes" do
      task = task_fixture()

      attrs = %{title: "Updated Task", description: "Updated Description"}

      assert {:ok, %Task{} = updated_task} = TaskRepositoryEcto.update_task(task, attrs)
      assert updated_task.title == "Updated Task"
      assert updated_task.description == "Updated Description"
    end

    test "returns error changeset with invalid attributes" do
      task = task_fixture()
      attrs = %{title: nil, description: "Updated Description", status: :in_progress}

      assert {:error, %Ecto.Changeset{} = changeset} =
               TaskRepositoryEcto.update_task(task, attrs)

      assert changeset.valid? == false
    end
  end
end
