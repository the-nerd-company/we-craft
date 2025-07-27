defmodule WeCraft.Milestones.Infrastructure.Ecto.TaskRepositoryEctoTest do
  @moduledoc """
  Tests for the TaskRepositoryEcto module.
  """
  use WeCraft.DataCase, async: true

  alias WeCraft.Milestones.Infrastructure.Ecto.TaskRepositoryEcto
  alias WeCraft.Milestones.Task

  import WeCraft.MilestonesFixtures

  describe "create_task/1" do
    test "creates a task with valid attributes" do
      milestone = milestone_fixture()

      attrs = %{
        title: "Test Task",
        description: "Test Desc",
        status: :planned,
        milestone_id: milestone.id
      }

      assert {:ok, %Task{} = task} = TaskRepositoryEcto.create_task(attrs)
      assert task.title == "Test Task"
      assert task.description == "Test Desc"
      assert task.status == :planned
      assert task.milestone_id == milestone.id
    end

    test "returns error changeset with invalid attributes" do
      attrs = %{title: nil, description: "Test Desc", status: :planned, milestone_id: nil}
      assert {:error, %Ecto.Changeset{} = changeset} = TaskRepositoryEcto.create_task(attrs)
      refute changeset.valid?
    end
  end

  describe "update_task/2" do
    test "updates a task with valid attributes" do
      task = task_fixture()
      attrs = %{title: "Updated Task", description: "Updated Desc"}
      assert {:ok, %Task{} = updated} = TaskRepositoryEcto.update_task(task, attrs)
      assert updated.title == "Updated Task"
      assert updated.description == "Updated Desc"
    end

    test "returns error changeset with invalid attributes" do
      task = task_fixture()
      attrs = %{title: nil}
      assert {:error, %Ecto.Changeset{} = changeset} = TaskRepositoryEcto.update_task(task, attrs)
      refute changeset.valid?
    end
  end

  describe "get_task!/1 and get_task/1" do
    test "returns the task by id" do
      task = task_fixture()
      found = TaskRepositoryEcto.get_task!(task.id)
      assert found.id == task.id
      assert {:ok, found2} = TaskRepositoryEcto.get_task(task.id)
      assert found2.id == task.id
    end

    test "returns error for unknown id" do
      assert {:error, :not_found} = TaskRepositoryEcto.get_task(-1)
      assert_raise Ecto.NoResultsError, fn -> TaskRepositoryEcto.get_task!(-1) end
    end
  end

  describe "get_task_with_milestone/1" do
    test "returns the task with milestone preloaded" do
      milestone = milestone_fixture()
      task = task_fixture(%{milestone_id: milestone.id})
      assert {:ok, found} = TaskRepositoryEcto.get_task_with_milestone(task.id)
      assert found.id == task.id
      assert found.milestone.id == milestone.id
    end

    test "returns error for unknown id" do
      assert {:error, :not_found} = TaskRepositoryEcto.get_task_with_milestone(-1)
    end
  end

  describe "list_milestone_tasks/1" do
    test "returns all tasks for a milestone" do
      milestone = milestone_fixture()
      task_fixture(%{milestone_id: milestone.id, title: "Task 1"})
      task_fixture(%{milestone_id: milestone.id, title: "Task 2"})
      {:ok, tasks} = TaskRepositoryEcto.list_milestone_tasks(milestone.id)
      titles = Enum.map(tasks, & &1.title)
      assert "Task 1" in titles
      assert "Task 2" in titles
    end
  end

  describe "delete_task/1" do
    test "deletes the task" do
      task = task_fixture()
      assert {:ok, %Task{}} = TaskRepositoryEcto.delete_task(task)
      assert {:error, :not_found} = TaskRepositoryEcto.get_task(task.id)
    end
  end
end
