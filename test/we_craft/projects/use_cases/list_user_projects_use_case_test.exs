defmodule WeCraft.Projects.UseCases.ListUserProjectsUseCaseTest do
  @moduledoc """
  Tests for the ListUserProjectsUseCase module.
  """
  use WeCraft.DataCase

  alias WeCraft.Projects

  import WeCraft.AccountsFixtures
  import WeCraft.ProjectsFixtures

  describe "list_user_projects/1" do
    setup do
      user1 = user_fixture()
      user2 = user_fixture()

      # Create several projects for user1
      project1 = project_fixture(%{owner: user1, title: "User1 Project 1"})
      project2 = project_fixture(%{owner: user1, title: "User1 Project 2"})
      project3 = project_fixture(%{owner: user1, title: "User1 Project 3", status: :live})

      # Create one project for user2
      project4 = project_fixture(%{owner: user2, title: "User2 Project"})

      %{
        user1: user1,
        user2: user2,
        user1_projects: [project1, project2, project3],
        user2_projects: [project4]
      }
    end

    test "returns all projects for a user", %{user1: user1, user1_projects: user1_projects} do
      assert {:ok, projects} = Projects.list_user_projects(%{user_id: user1.id})

      assert length(projects) == 3

      project_ids = Enum.map(projects, & &1.id) |> Enum.sort()
      expected_ids = Enum.map(user1_projects, & &1.id) |> Enum.sort()

      assert project_ids == expected_ids
    end

    test "returns an empty list when user has no projects" do
      user_without_projects = user_fixture()

      assert {:ok, projects} =
               Projects.list_user_projects(%{user_id: user_without_projects.id})

      assert projects == []
    end

    test "returns correct projects for different users", %{
      user2: user2,
      user2_projects: user2_projects
    } do
      assert {:ok, projects} = Projects.list_user_projects(%{user_id: user2.id})

      assert length(projects) == 1

      [project] = projects
      [expected_project] = user2_projects

      assert project.id == expected_project.id
      assert project.title == "User2 Project"
    end

    test "returns only projects for the specified user", %{user1: user1, user2: user2} do
      # Get projects for user1
      {:ok, user1_projects} = Projects.list_user_projects(%{user_id: user1.id})

      # Get projects for user2
      {:ok, user2_projects} = Projects.list_user_projects(%{user_id: user2.id})

      # Ensure no overlap between the two sets of projects
      user1_project_ids = Enum.map(user1_projects, & &1.id) |> MapSet.new()
      user2_project_ids = Enum.map(user2_projects, & &1.id) |> MapSet.new()

      assert MapSet.intersection(user1_project_ids, user2_project_ids) |> Enum.empty?()
    end

    test "includes projects with different statuses", %{user1: user1} do
      {:ok, projects} = Projects.list_user_projects(%{user_id: user1.id})

      # Verify we have both :idea and :live status projects
      statuses = Enum.map(projects, & &1.status) |> Enum.sort() |> Enum.uniq()

      assert :idea in statuses
      assert :live in statuses
    end
  end
end
