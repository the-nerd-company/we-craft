defmodule WeCraft.Projects.UseCases.ListProjectsUseCaseTest do
  @moduledoc """
  This module contains tests for the ListProjectsUseCase.
  """
  use WeCraft.DataCase

  alias WeCraft.Projects

  import WeCraft.ProjectsFixtures
  import WeCraft.AccountsFixtures

  describe "list_projects/1" do
    setup do
      user = user_fixture()

      # Create a variety of projects for testing
      project1 =
        project_fixture(%{
          title: "Elixir API Service",
          description: "A backend API service built with Elixir",
          status: :idea,
          visibility: :public,
          tags: ["elixir", "phoenix"],
          business_domains: ["saas", "productivity"],
          owner_id: user.id
        })

      project2 =
        project_fixture(%{
          title: "React Dashboard",
          description: "A frontend dashboard built with React",
          status: :in_dev,
          visibility: :public,
          tags: ["javascript", "react", "tailwind"],
          business_domains: ["saas", "analytics"],
          owner_id: user.id
        })

      project3 =
        project_fixture(%{
          title: "Health Monitoring App",
          description: "A mobile app for health monitoring",
          status: :live,
          visibility: :public,
          tags: ["swift", "kotlin"],
          business_domains: ["healthtech", "consumers"],
          owner_id: user.id
        })

      {:ok, user: user, projects: [project1, project2, project3]}
    end

    test "returns a list of all projects when no filters are applied", %{projects: projects} do
      {:ok, result} = Projects.list_projects(%{})
      # Compare by IDs since the result has preloaded associations while fixtures don't
      result_ids = Enum.sort(Enum.map(result, & &1.id))
      expected_ids = Enum.sort(Enum.map(projects, & &1.id))
      assert result_ids == expected_ids

      # Verify that each project has a followers_count field with default value 0
      assert Enum.all?(result, fn project -> project.followers_count == 0 end)
    end

    test "filters projects by tags", %{projects: [p1, p2, _p3]} do
      # Test single tag
      {:ok, elixir_projects} = Projects.list_projects(%{tags: ["elixir"]})
      assert length(elixir_projects) == 1
      assert Enum.at(elixir_projects, 0).id == p1.id

      # Test multiple tags (OR search)
      {:ok, js_projects} = Projects.list_projects(%{tags: ["javascript", "react"]})
      assert length(js_projects) == 1
      assert Enum.at(js_projects, 0).id == p2.id

      # Test no matches
      {:ok, no_matches} = Projects.list_projects(%{tags: ["nonexistent"]})
      assert no_matches == []
    end

    test "filters projects by title", %{projects: [p1, _p2, p3]} do
      # Exact title match
      {:ok, api_projects} = Projects.list_projects(%{title: "API"})
      assert length(api_projects) == 1
      assert Enum.at(api_projects, 0).id == p1.id

      # Partial match, case insensitive
      {:ok, app_projects} = Projects.list_projects(%{title: "app"})
      assert length(app_projects) == 1
      assert Enum.at(app_projects, 0).id == p3.id

      # No matches
      {:ok, no_matches} = Projects.list_projects(%{title: "nonexistent"})
      assert no_matches == []
    end

    test "filters projects by business domains", %{projects: [p1, p2, _p3]} do
      # Test single business domain
      {:ok, saas_projects} = Projects.list_projects(%{business_domains: ["saas"]})
      assert length(saas_projects) == 2

      # Compare IDs instead of complete records since owner association loading may differ
      saas_project_ids = Enum.map(saas_projects, & &1.id) |> Enum.sort()
      expected_ids = [p1.id, p2.id] |> Enum.sort()
      assert saas_project_ids == expected_ids

      # Test single domain with one match
      {:ok, productivity_projects} = Projects.list_projects(%{business_domains: ["productivity"]})
      assert length(productivity_projects) == 1
      assert Enum.at(productivity_projects, 0).id == p1.id

      # Test no matches
      {:ok, no_matches} = Projects.list_projects(%{business_domains: ["nonexistent"]})
      assert no_matches == []
    end

    test "filters projects by status", %{projects: [p1, _p2, p3]} do
      # Test single status
      {:ok, idea_projects} = Projects.list_projects(%{status: :idea})
      assert length(idea_projects) == 1
      assert Enum.at(idea_projects, 0).id == p1.id

      {:ok, live_projects} = Projects.list_projects(%{status: :live})
      assert length(live_projects) == 1
      assert Enum.at(live_projects, 0).id == p3.id
    end

    test "combines filters", %{projects: [p1, p2, _p3]} do
      # Combine tags and title
      {:ok, results} = Projects.list_projects(%{tags: ["elixir"], title: "API"})
      assert length(results) == 1
      assert Enum.at(results, 0).id == p1.id

      # Combine business domains and status
      {:ok, results} = Projects.list_projects(%{business_domains: ["saas"], status: :in_dev})
      assert length(results) == 1
      assert Enum.at(results, 0).id == p2.id

      # Combine tags, business domains and title
      {:ok, results} =
        Projects.list_projects(%{
          tags: ["javascript", "react"],
          business_domains: ["analytics"],
          title: "dash"
        })

      assert length(results) == 1
      assert Enum.at(results, 0).id == p2.id

      # All filters together
      {:ok, results} =
        Projects.list_projects(%{
          tags: ["elixir"],
          title: "API",
          business_domains: ["saas"],
          status: :idea
        })

      assert length(results) == 1
      assert Enum.at(results, 0).id == p1.id

      # No matches for combined filters
      {:ok, no_matches} =
        Projects.list_projects(%{
          tags: ["elixir"],
          status: :live
        })

      assert no_matches == []
    end
  end
end
