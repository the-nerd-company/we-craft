defmodule WeCraft.Milestones.UseCases.DeleteMilestoneUseCaseTest do
  @moduledoc """
  Tests for the DeleteMilestoneUseCase.
  """
  use WeCraft.DataCase, async: true

  alias WeCraft.Milestones

  describe "delete_milestone/1" do
    test "deletes milestone when user has permission" do
      user = WeCraft.AccountsFixtures.user_fixture()
      scope = WeCraft.AccountsFixtures.user_scope_fixture(user)
      project = WeCraft.ProjectsFixtures.project_fixture(%{owner: user})

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

      # Verify milestone is deleted by checking the list
      assert {:ok, []} =
               Milestones.list_project_milestones(%{
                 project_id: project.id,
                 scope: scope
               })
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

      assert {:error, :unauthorized} =
               Milestones.delete_milestone(%{
                 milestone_id: milestone.id,
                 scope: scope
               })
    end

    test "returns error when milestone doesn't exist" do
      user = WeCraft.AccountsFixtures.user_fixture()
      scope = WeCraft.AccountsFixtures.user_scope_fixture(user)

      assert {:error, :not_found} =
               Milestones.delete_milestone(%{
                 milestone_id: 99_999,
                 scope: scope
               })
    end
  end
end
