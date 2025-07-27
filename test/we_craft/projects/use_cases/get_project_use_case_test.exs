defmodule WeCraft.Projects.UseCases.GetProjectUseCaseTest do
  @moduledoc """
  Tests for the GetProjectUseCase module.
  """
  use WeCraft.DataCase

  alias WeCraft.Accounts.Scope
  alias WeCraft.Projects
  alias WeCraft.Projects.Project

  import WeCraft.AccountsFixtures
  import WeCraft.ProjectsFixtures

  describe "get_project/1" do
    setup do
      user = user_fixture()
      project = project_fixture(%{owner: user})
      scope = Scope.for_user(user)

      %{user: user, project: project, scope: scope}
    end

    test "returns a project when given a valid id", %{project: project, scope: scope} do
      assert {:ok, found_project} =
               Projects.get_project(%{project_id: project.id, scope: scope})

      assert %Project{} = found_project
      assert found_project.id == project.id
      assert found_project.title == project.title
      assert found_project.description == project.description

      # Check that owner is preloaded
      assert found_project.owner != nil
      assert found_project.owner.id == project.owner_id
    end

    test "returns nil when project doesn't exist", %{scope: scope} do
      non_existent_id = -1

      assert {:ok, nil} =
               Projects.get_project(%{project_id: non_existent_id, scope: scope})
    end

    test "works with different project statuses", %{user: user, scope: scope} do
      live_project = project_fixture(%{owner: user, status: :live})

      assert {:ok, found_project} =
               Projects.get_project(%{project_id: live_project.id, scope: scope})

      assert found_project.id == live_project.id
      assert found_project.status == :live
    end
  end
end
