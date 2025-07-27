defmodule WeCraft.Pages.Infrastructure.Ecto.PageRepositoryEctoTest do
  @moduledoc """
  Tests for the PageRepositoryEcto module.
  """
  use WeCraft.DataCase

  alias WeCraft.Pages.Infrastructure.Ecto.PageRepositoryEcto
  alias WeCraft.Pages.Page
  alias WeCraft.PagesFixtures
  alias WeCraft.ProjectsFixtures
  alias WeCraft.Repo

  describe "create_page/1" do
    test "creates a page with valid attributes" do
      project = ProjectsFixtures.project_fixture()

      attrs = %{
        title: "Test Page",
        slug: "test-page",
        project_id: project.id
      }

      assert {:ok, %Page{} = page} = PageRepositoryEcto.create_page(attrs)
      assert page.title == "Test Page"
      assert page.slug == "test-page"
      assert page.project_id == project.id
    end

    test "creates a page with parent page" do
      parent_page = PagesFixtures.page_fixture()

      attrs = %{
        title: "Child Page",
        slug: "child-page",
        project_id: parent_page.project_id,
        parent_page_id: parent_page.id,
        parent_id: parent_page.id
      }

      assert {:ok, %Page{} = page} = PageRepositoryEcto.create_page(attrs)
      assert page.parent_page_id == parent_page.id
      assert page.parent_id == parent_page.id
    end

    test "returns error with invalid attributes" do
      attrs = %{title: nil, content: nil, slug: nil}

      assert {:error, %Ecto.Changeset{}} = PageRepositoryEcto.create_page(attrs)
    end

    test "returns error with duplicate slug" do
      page = PagesFixtures.page_fixture(%{slug: "unique-slug"})

      attrs = %{
        title: "Another Page",
        slug: "unique-slug",
        project_id: page.project_id
      }

      assert {:error, %Ecto.Changeset{}} = PageRepositoryEcto.create_page(attrs)
    end
  end

  describe "update_page/2" do
    test "updates a page with valid attributes" do
      page = PagesFixtures.page_fixture()

      update_attrs = %{
        title: "Updated Title"
      }

      assert {:ok, %Page{} = updated_page} = PageRepositoryEcto.update_page(page, update_attrs)
      assert updated_page.title == "Updated Title"
      # slug should remain unchanged
      assert updated_page.slug == page.slug
    end

    test "updates page slug" do
      page = PagesFixtures.page_fixture()

      update_attrs = %{slug: "new-slug"}

      assert {:ok, %Page{} = updated_page} = PageRepositoryEcto.update_page(page, update_attrs)
      assert updated_page.slug == "new-slug"
    end

    test "returns error with invalid attributes" do
      page = PagesFixtures.page_fixture()

      update_attrs = %{title: nil}

      assert {:error, %Ecto.Changeset{}} = PageRepositoryEcto.update_page(page, update_attrs)
    end

    test "returns error when updating to duplicate slug" do
      _page1 = PagesFixtures.page_fixture(%{slug: "existing-slug"})
      page2 = PagesFixtures.page_fixture(%{slug: "different-slug"})

      update_attrs = %{slug: "existing-slug"}

      assert {:error, %Ecto.Changeset{}} = PageRepositoryEcto.update_page(page2, update_attrs)
    end
  end

  describe "page relationships" do
    test "page belongs to project" do
      project = ProjectsFixtures.project_fixture()
      page = PagesFixtures.page_fixture(%{project: project})

      page_with_project = Repo.preload(page, :project)
      assert page_with_project.project.id == project.id
    end

    test "page can have parent page" do
      parent_page = PagesFixtures.page_fixture()
      child_page = PagesFixtures.page_with_parent_fixture(%{parent_page: parent_page})

      child_with_parent = Repo.preload(child_page, :parent_page)
      assert child_with_parent.parent_page.id == parent_page.id
    end

    test "page can have children pages" do
      parent_page = PagesFixtures.page_fixture()
      child1 = PagesFixtures.page_with_parent_fixture(%{parent_page: parent_page})
      child2 = PagesFixtures.page_with_parent_fixture(%{parent_page: parent_page})

      parent_with_children = Repo.preload(parent_page, :children)
      child_ids = Enum.map(parent_with_children.children, & &1.id)
      assert child1.id in child_ids
      assert child2.id in child_ids
      assert length(parent_with_children.children) == 2
    end
  end

  describe "list_project_pages/1" do
    test "returns only top-level pages for a project, ordered by title" do
      project = ProjectsFixtures.project_fixture()
      # Top-level pages
      page_a = PagesFixtures.page_fixture(%{title: "Alpha", project: project})
      page_b = PagesFixtures.page_fixture(%{title: "Beta", project: project})
      # Child page (should not be included)
      _child = PagesFixtures.page_with_parent_fixture(%{parent_page: page_a, project: project})
      # Page for another project (should not be included)
      other_project = ProjectsFixtures.project_fixture()
      _other_page = PagesFixtures.page_fixture(%{title: "Other", project: other_project})

      result = PageRepositoryEcto.list_project_pages(project.id)

      assert Enum.map(result, & &1.id) ==
               Enum.sort_by([page_a, page_b], & &1.title) |> Enum.map(& &1.id)

      assert Enum.all?(result, &is_nil(&1.parent_page_id))
    end

    test "returns empty list if project has no pages" do
      project = ProjectsFixtures.project_fixture()
      assert PageRepositoryEcto.list_project_pages(project.id) == []
    end
  end
end
