defmodule WeCraft.MilestonesTest do
  @moduledoc """
  Tests for the Milestones context.
  """
  use WeCraft.DataCase, async: true

  alias WeCraft.Milestones
  alias WeCraft.Milestones.Milestone

  import WeCraft.ProjectsFixtures
  import WeCraft.AccountsFixtures

  describe "create_milestone/1" do
    test "creates milestone with valid attributes" do
      user = user_fixture()
      scope = user_scope_fixture(user)
      project = project_fixture(%{owner: user})

      attrs = %{
        title: "Test Milestone",
        description: "A test milestone description",
        status: "planned",
        project_id: project.id
      }

      assert {:ok, %Milestone{} = milestone} =
               Milestones.create_milestone(%{attrs: attrs, scope: scope})

      assert milestone.title == "Test Milestone"
      assert milestone.description == "A test milestone description"
      assert milestone.status == :planned
      assert milestone.project_id == project.id
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

      assert {:error, %Ecto.Changeset{}} =
               Milestones.create_milestone(%{attrs: attrs, scope: scope})
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

      assert {:error, :unauthorized} = Milestones.create_milestone(%{attrs: attrs, scope: scope})
    end
  end

  describe "list_project_milestones/1" do
    test "returns all milestones for a project" do
      user = user_fixture()
      scope = user_scope_fixture(user)
      project = project_fixture(%{owner: user})

      # Create milestones
      attrs1 = %{
        title: "Milestone 1",
        description: "Description 1",
        status: "planned",
        project_id: project.id
      }

      attrs2 = %{
        title: "Milestone 2",
        description: "Description 2",
        status: "active",
        project_id: project.id
      }

      {:ok, milestone1} = Milestones.create_milestone(%{attrs: attrs1, scope: scope})
      {:ok, milestone2} = Milestones.create_milestone(%{attrs: attrs2, scope: scope})

      assert {:ok, milestones} =
               Milestones.list_project_milestones(%{project_id: project.id, scope: scope})

      assert length(milestones) == 2

      milestone_ids = Enum.map(milestones, & &1.id)
      assert milestone1.id in milestone_ids
      assert milestone2.id in milestone_ids
    end

    test "returns empty list for project with no milestones" do
      user = user_fixture()
      scope = user_scope_fixture(user)
      project = project_fixture(%{owner: user})

      assert {:ok, []} =
               Milestones.list_project_milestones(%{project_id: project.id, scope: scope})
    end

    test "returns error when user doesn't have permission" do
      user = user_fixture()
      other_user = user_fixture()
      scope = user_scope_fixture(user)
      project = project_fixture(%{owner: other_user})

      assert {:error, :unauthorized} =
               Milestones.list_project_milestones(%{project_id: project.id, scope: scope})
    end
  end

  describe "update_milestone/1" do
    test "updates milestone with valid attributes" do
      user = user_fixture()
      scope = user_scope_fixture(user)
      project = project_fixture(%{owner: user})

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
    end

    test "returns error with invalid attributes" do
      user = user_fixture()
      scope = user_scope_fixture(user)
      project = project_fixture(%{owner: user})

      attrs = %{
        title: "Original Title",
        description: "Original Description",
        status: "planned",
        project_id: project.id
      }

      {:ok, milestone} = Milestones.create_milestone(%{attrs: attrs, scope: scope})

      update_attrs = %{title: "", description: ""}

      assert {:error, %Ecto.Changeset{}} =
               Milestones.update_milestone(%{
                 milestone_id: milestone.id,
                 attrs: update_attrs,
                 scope: scope
               })
    end

    test "returns error when user doesn't have permission" do
      user = user_fixture()
      other_user = user_fixture()
      scope = user_scope_fixture(user)
      project = project_fixture(%{owner: other_user})

      attrs = %{
        title: "Title",
        description: "Description",
        status: "planned",
        project_id: project.id
      }

      other_scope = user_scope_fixture(other_user)
      {:ok, milestone} = Milestones.create_milestone(%{attrs: attrs, scope: other_scope})

      update_attrs = %{title: "Updated Title"}

      assert {:error, :unauthorized} =
               Milestones.update_milestone(%{
                 milestone_id: milestone.id,
                 attrs: update_attrs,
                 scope: scope
               })
    end
  end

  describe "delete_milestone/1" do
    test "deletes milestone when user has permission" do
      user = user_fixture()
      scope = user_scope_fixture(user)
      project = project_fixture(%{owner: user})

      attrs = %{
        title: "Title",
        description: "Description",
        status: "planned",
        project_id: project.id
      }

      {:ok, milestone} = Milestones.create_milestone(%{attrs: attrs, scope: scope})

      assert {:ok, deleted_milestone} =
               Milestones.delete_milestone(%{
                 milestone_id: milestone.id,
                 scope: scope
               })

      assert deleted_milestone.id == milestone.id

      # Verify milestone is deleted
      assert {:ok, []} =
               Milestones.list_project_milestones(%{project_id: project.id, scope: scope})
    end

    test "returns error when user doesn't have permission" do
      user = user_fixture()
      other_user = user_fixture()
      scope = user_scope_fixture(user)
      project = project_fixture(%{owner: other_user})

      attrs = %{
        title: "Title",
        description: "Description",
        status: "planned",
        project_id: project.id
      }

      other_scope = user_scope_fixture(other_user)
      {:ok, milestone} = Milestones.create_milestone(%{attrs: attrs, scope: other_scope})

      assert {:error, :unauthorized} =
               Milestones.delete_milestone(%{
                 milestone_id: milestone.id,
                 scope: scope
               })
    end
  end
end
