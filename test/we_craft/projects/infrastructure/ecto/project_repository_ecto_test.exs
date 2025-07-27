defmodule WeCraft.Projects.Infrastructure.Ecto.ProjectRepositoryEctoTest do
  @moduledoc """
  Tests for the ProjectRepositoryEcto module.
  """
  use WeCraft.DataCase

  alias WeCraft.Projects.Infrastructure.Ecto.ProjectRepositoryEcto
  alias WeCraft.Projects.Project
  alias WeCraft.Repo

  describe "search_projects/1" do
    setup do
      # Create a user for testing
      user = WeCraft.AccountsFixtures.user_fixture()

      # Create some test projects with different tags
      project1 = %Project{
        title: "Elixir App",
        description: "A project built with Elixir",
        status: :idea,
        visibility: :public,
        tags: ["elixir", "phoenix"],
        owner_id: user.id
      }

      project2 = %Project{
        title: "JavaScript Application",
        description: "A project built with JavaScript",
        status: :in_dev,
        visibility: :public,
        tags: ["javascript", "react"],
        owner_id: user.id
      }

      project3 = %Project{
        title: "Full Stack Project",
        description: "A project with both frontend and backend",
        status: :live,
        visibility: :public,
        tags: ["javascript", "elixir", "postgresql"],
        owner_id: user.id
      }

      {:ok, p1} = Repo.insert(project1)
      {:ok, p2} = Repo.insert(project2)
      {:ok, p3} = Repo.insert(project3)

      %{projects: [p1, p2, p3], user: user}
    end

    test "search by tags returns projects with any of the given tags", %{projects: [p1, p2, p3]} do
      # Search for projects with 'elixir' tag
      results = ProjectRepositoryEcto.search_projects(%{tags: ["elixir"]})
      assert length(results) == 2
      assert Enum.any?(results, fn p -> p.id == p1.id end)
      assert Enum.any?(results, fn p -> p.id == p3.id end)

      # Search for projects with 'javascript' tag
      results = ProjectRepositoryEcto.search_projects(%{tags: ["javascript"]})
      assert length(results) == 2
      assert Enum.any?(results, fn p -> p.id == p2.id end)
      assert Enum.any?(results, fn p -> p.id == p3.id end)

      # Search for projects with 'elixir' OR 'react' tags
      results = ProjectRepositoryEcto.search_projects(%{tags: ["elixir", "react"]})
      assert length(results) == 3
    end

    test "search by title returns projects with matching titles", %{projects: [p1, p2, _p3]} do
      # Search for 'App' in title (case insensitive)
      results = ProjectRepositoryEcto.search_projects(%{title: "app"})
      assert length(results) == 2
      assert Enum.any?(results, fn p -> p.id == p1.id end)
      assert Enum.any?(results, fn p -> p.id == p2.id end)

      # Search for 'JavaScript' in title
      results = ProjectRepositoryEcto.search_projects(%{title: "JavaScript"})
      assert length(results) == 1
      assert hd(results).id == p2.id
    end

    test "search by both tags and title", %{projects: [p1, _p2, p3]} do
      # Search for projects with 'elixir' tag and 'app' in title
      results = ProjectRepositoryEcto.search_projects(%{tags: ["elixir"], title: "app"})
      assert length(results) == 1
      assert hd(results).id == p1.id

      # Search for projects with 'javascript' tag and 'project' in title
      results = ProjectRepositoryEcto.search_projects(%{tags: ["javascript"], title: "project"})
      assert length(results) == 1
      assert hd(results).id == p3.id
    end

    test "search with empty parameters returns expected results", %{} do
      # Empty tags list should be ignored
      results = ProjectRepositoryEcto.search_projects(%{tags: []})
      assert length(results) == 3

      # Empty title should be ignored
      results = ProjectRepositoryEcto.search_projects(%{title: ""})
      assert length(results) == 3

      # No matching tag should return empty list
      results = ProjectRepositoryEcto.search_projects(%{tags: ["nonexistent"]})
      assert results == []

      # No matching title should return empty list
      results = ProjectRepositoryEcto.search_projects(%{title: "nonexistent"})
      assert results == []
    end
  end
end
