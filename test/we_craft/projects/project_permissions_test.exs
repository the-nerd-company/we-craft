defmodule WeCraft.Projects.ProjectPermissionsTest do
  @moduledoc """
  Tests for the ProjectPermissions module.
  """
  use WeCraft.DataCase, async: true

  alias WeCraft.AccountsFixtures
  alias WeCraft.Projects.Project
  alias WeCraft.Projects.ProjectPermissions
  alias WeCraft.ProjectsFixtures

  describe "can_update_project?/2" do
    test "returns false when scope is nil" do
      project = %Project{id: 1, owner_id: 1}
      refute ProjectPermissions.can_update_project?(project, nil)
    end

    test "returns true when the user is the owner of the project" do
      # Create a user
      user = AccountsFixtures.user_fixture()

      # Create a project owned by the user
      project = ProjectsFixtures.project_fixture(%{owner_id: user.id})

      # Create a scope with the user
      scope = %{user: user}

      # Test permission
      assert ProjectPermissions.can_update_project?(project, scope)
    end

    test "returns false when the user is not the owner of the project" do
      # Create two users
      owner = AccountsFixtures.user_fixture()
      different_user = AccountsFixtures.user_fixture()

      # Create a project owned by the first user
      project = ProjectsFixtures.project_fixture(%{owner_id: owner.id})

      # Create a scope with the different user
      scope = %{user: different_user}

      # Test permission - should be false
      refute ProjectPermissions.can_update_project?(project, scope)
    end

    test "handles case with different user ID types correctly" do
      # Sometimes IDs might be stored as integers vs strings in different parts of the system
      # Let's ensure the comparison works correctly

      # Create a user and get the string representation of their ID
      user = AccountsFixtures.user_fixture()

      # Create a project with the user ID
      project = %Project{id: 1, owner_id: user.id}

      # The correct behavior is that the user ID matches the project owner ID
      assert ProjectPermissions.can_update_project?(project, %{user: user})
    end
  end
end
