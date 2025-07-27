defmodule WeCraft.ProjectsTest do
  @moduledoc """
  Tests for the WeCraft.Projects module.
  """

  use WeCraft.DataCase

  alias WeCraft.Projects

  describe "search_projects/1" do
    setup do
      # Create a user for testing
      user = WeCraft.AccountsFixtures.user_fixture()

      # Create test projects
      {:ok, project1} =
        Projects.create_project(%{
          attrs: %{
            title: "Elixir API Service",
            description: "A backend API service built with Elixir",
            status: :idea,
            visibility: :public,
            tags: ["elixir", "phoenix", "node"],
            owner_id: user.id
          }
        })

      {:ok, project2} =
        Projects.create_project(%{
          attrs: %{
            title: "React Dashboard",
            description: "A frontend dashboard built with React",
            status: :in_dev,
            visibility: :public,
            tags: ["javascript", "react", "tailwind"],
            owner_id: user.id
          }
        })

      {:ok, project3} =
        Projects.create_project(%{
          attrs: %{
            title: "DevOps Tooling",
            description: "A collection of DevOps tools",
            status: :live,
            visibility: :public,
            tags: ["docker", "kubernetes", "aws"],
            owner_id: user.id
          }
        })

      %{projects: [project1, project2, project3], user: user}
    end

    test "can search projects by tag", %{projects: [p1, p2, p3]} do
      # Search by single tag
      {:ok, results} = Projects.search_projects(%{tags: ["elixir"]})
      assert length(results) == 1
      assert Enum.at(results, 0).id == p1.id

      {:ok, results} = Projects.search_projects(%{tags: ["javascript"]})
      assert length(results) == 1
      assert Enum.at(results, 0).id == p2.id

      # Search by multiple tags (OR search)
      {:ok, results} = Projects.search_projects(%{tags: ["elixir", "react"]})
      assert length(results) == 2

      # Search for DevOps tags
      {:ok, results} = Projects.search_projects(%{tags: ["docker"]})
      assert length(results) == 1
      assert Enum.at(results, 0).id == p3.id
    end

    test "can search projects by title", %{projects: [p1, p2, p3]} do
      # Exact title matches
      {:ok, results} = Projects.search_projects(%{title: "Elixir API Service"})
      assert length(results) == 1
      assert Enum.at(results, 0).id == p1.id

      # Partial matches (case-insensitive)
      {:ok, results} = Projects.search_projects(%{title: "api"})
      assert length(results) == 1
      assert Enum.at(results, 0).id == p1.id

      {:ok, results} = Projects.search_projects(%{title: "dash"})
      assert length(results) == 1
      assert Enum.at(results, 0).id == p2.id

      {:ok, results} = Projects.search_projects(%{title: "tool"})
      assert length(results) == 1
      assert Enum.at(results, 0).id == p3.id
    end

    test "can search projects by both tags and title", %{projects: [p1, _p2, _p3]} do
      # Project with 'elixir' tag and 'api' in title
      {:ok, results} = Projects.search_projects(%{tags: ["elixir"], title: "api"})
      assert length(results) == 1
      assert Enum.at(results, 0).id == p1.id

      # No projects with 'elixir' tag and 'dashboard' in title
      {:ok, results} = Projects.search_projects(%{tags: ["elixir"], title: "dashboard"})
      assert results == []
    end

    test "returns all projects when search parameters are empty" do
      {:ok, all_projects} = Projects.list_projects(%{})
      {:ok, search_results} = Projects.search_projects(%{tags: [], title: ""})
      assert length(all_projects) == length(search_results)

      # Nonexistent values
      {:ok, results} = Projects.search_projects(%{tags: ["nonexistent"], title: "nonexistent"})
      assert results == []
    end
  end
end
