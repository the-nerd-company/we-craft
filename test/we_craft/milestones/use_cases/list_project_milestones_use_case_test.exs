defmodule WeCraft.Milestones.UseCases.ListProjectMilestonesUseCaseTest do
  @moduledoc """
  Tests for the ListProjectMilestonesUseCase.
  """
  use WeCraft.DataCase, async: true

  alias WeCraft.Milestones

  describe "list_project_milestones/1" do
    test "returns all milestones for a project when user has permission" do
      user = WeCraft.AccountsFixtures.user_fixture()
      scope = WeCraft.AccountsFixtures.user_scope_fixture(user)
      project = WeCraft.ProjectsFixtures.project_fixture(%{owner: user})

      # Create milestones using the context
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

      {:ok, milestone1} = WeCraft.Milestones.create_milestone(%{attrs: attrs1, scope: scope})
      {:ok, milestone2} = WeCraft.Milestones.create_milestone(%{attrs: attrs2, scope: scope})

      assert {:ok, milestones} =
               Milestones.list_project_milestones(%{
                 project_id: project.id,
                 scope: scope
               })

      assert length(milestones) == 2

      milestone_ids = Enum.map(milestones, & &1.id)
      assert milestone1.id in milestone_ids
      assert milestone2.id in milestone_ids
    end

    test "returns empty list for project with no milestones" do
      user = WeCraft.AccountsFixtures.user_fixture()
      scope = WeCraft.AccountsFixtures.user_scope_fixture(user)
      project = WeCraft.ProjectsFixtures.project_fixture(%{owner: user})

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

      assert {:error, :unauthorized} =
               Milestones.list_project_milestones(%{
                 project_id: project.id,
                 scope: scope
               })
    end

    test "returns error when project doesn't exist" do
      user = WeCraft.AccountsFixtures.user_fixture()
      scope = WeCraft.AccountsFixtures.user_scope_fixture(user)

      assert {:error, :project_not_found} =
               Milestones.list_project_milestones(%{
                 project_id: 99_999,
                 scope: scope
               })
    end
  end
end
