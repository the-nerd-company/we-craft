defmodule WeCraft.Pages.UseCases.CreatePageUseCaseTest do
  @moduledoc """
  Tests for the CreatePageUseCase module.
  """
  use WeCraft.DataCase

  alias WeCraft.Pages.Page
  alias WeCraft.Pages.UseCases.CreatePageUseCase
  alias WeCraft.PagesFixtures
  alias WeCraft.ProjectsFixtures

  describe "create_page/1" do
    test "creates a page with valid attributes and permissions" do
      user = WeCraft.AccountsFixtures.user_fixture()
      scope = WeCraft.AccountsFixtures.user_scope_fixture(user)
      project = ProjectsFixtures.project_fixture(%{owner: user})

      attrs = %{
        title: "Getting Started Guide",
        slug: "getting-started-guide",
        project_id: project.id
      }

      assert {:ok, %Page{} = page} =
               CreatePageUseCase.create_page(%{
                 attrs: attrs,
                 project: project,
                 scope: scope
               })

      assert page.title == "Getting Started Guide"
      assert page.slug == "getting-started-guide"
      assert page.project_id == project.id
      assert is_nil(page.parent_page_id)
      assert is_nil(page.parent_id)
    end

    test "creates a page with parent page" do
      user = WeCraft.AccountsFixtures.user_fixture()
      scope = WeCraft.AccountsFixtures.user_scope_fixture(user)
      project = ProjectsFixtures.project_fixture(%{owner: user})
      parent_page = PagesFixtures.page_fixture(%{project: project})

      attrs = %{
        title: "Chapter 1: Introduction",
        slug: "chapter-1-introduction",
        project_id: project.id,
        parent_page_id: parent_page.id,
        parent_id: parent_page.id
      }

      assert {:ok, %Page{} = page} =
               CreatePageUseCase.create_page(%{
                 attrs: attrs,
                 project: project,
                 scope: scope
               })

      assert page.title == "Chapter 1: Introduction"
      assert page.parent_page_id == parent_page.id
      assert page.parent_id == parent_page.id
      assert page.project_id == project.id
    end

    test "returns error when user doesn't have permission" do
      user = WeCraft.AccountsFixtures.user_fixture()
      other_user = WeCraft.AccountsFixtures.user_fixture()
      scope = WeCraft.AccountsFixtures.user_scope_fixture(user)
      project = ProjectsFixtures.project_fixture(%{owner: other_user})

      attrs = %{
        title: "Test Page",
        slug: "test-page",
        project_id: project.id
      }

      assert {:error, :unauthorized} =
               CreatePageUseCase.create_page(%{
                 attrs: attrs,
                 project: project,
                 scope: scope
               })
    end

    test "returns error when scope is nil" do
      user = WeCraft.AccountsFixtures.user_fixture()
      project = ProjectsFixtures.project_fixture(%{owner: user})

      attrs = %{
        title: "Test Page",
        slug: "test-page",
        project_id: project.id
      }

      assert {:error, :unauthorized} =
               CreatePageUseCase.create_page(%{
                 attrs: attrs,
                 project: project,
                 scope: nil
               })
    end

    test "returns error with invalid attributes" do
      user = WeCraft.AccountsFixtures.user_fixture()
      scope = WeCraft.AccountsFixtures.user_scope_fixture(user)
      project = ProjectsFixtures.project_fixture(%{owner: user})

      attrs = %{
        title: "",
        slug: "",
        project_id: project.id
      }

      assert {:error, %Ecto.Changeset{} = changeset} =
               CreatePageUseCase.create_page(%{
                 attrs: attrs,
                 project: project,
                 scope: scope
               })

      assert errors_on(changeset) == %{
               title: ["can't be blank"],
               slug: ["can't be blank"]
             }
    end

    test "returns error with missing required fields" do
      user = WeCraft.AccountsFixtures.user_fixture()
      scope = WeCraft.AccountsFixtures.user_scope_fixture(user)
      project = ProjectsFixtures.project_fixture(%{owner: user})

      attrs = %{title: "Valid Title", project_id: project.id}

      assert {:error, %Ecto.Changeset{} = changeset} =
               CreatePageUseCase.create_page(%{
                 attrs: attrs,
                 project: project,
                 scope: scope
               })

      assert errors_on(changeset) == %{
               slug: ["can't be blank"]
             }
    end

    test "returns error with duplicate slug" do
      user = WeCraft.AccountsFixtures.user_fixture()
      scope = WeCraft.AccountsFixtures.user_scope_fixture(user)
      project = ProjectsFixtures.project_fixture(%{owner: user})
      _existing_page = PagesFixtures.page_fixture(%{slug: "unique-slug", project: project})

      attrs = %{
        title: "Another Page",
        slug: "unique-slug",
        project_id: project.id
      }

      assert {:error, %Ecto.Changeset{} = changeset} =
               CreatePageUseCase.create_page(%{
                 attrs: attrs,
                 project: project,
                 scope: scope
               })

      assert %{slug: ["has already been taken"]} = errors_on(changeset)
    end

    test "returns error with non-existent project_id" do
      user = WeCraft.AccountsFixtures.user_fixture()
      scope = WeCraft.AccountsFixtures.user_scope_fixture(user)
      project = ProjectsFixtures.project_fixture(%{owner: user})

      attrs = %{
        title: "Test Page",
        slug: "test-page",
        project_id: 99_999
      }

      assert_raise Ecto.ConstraintError, fn ->
        CreatePageUseCase.create_page(%{
          attrs: attrs,
          project: project,
          scope: scope
        })
      end
    end

    test "creates multiple pages for the same project" do
      user = WeCraft.AccountsFixtures.user_fixture()
      scope = WeCraft.AccountsFixtures.user_scope_fixture(user)
      project = ProjectsFixtures.project_fixture(%{owner: user})

      attrs1 = %{
        title: "Page 1",
        slug: "page-1",
        project_id: project.id
      }

      attrs2 = %{
        title: "Page 2",
        slug: "page-2",
        project_id: project.id
      }

      assert {:ok, %Page{} = page1} =
               CreatePageUseCase.create_page(%{attrs: attrs1, project: project, scope: scope})

      assert {:ok, %Page{} = page2} =
               CreatePageUseCase.create_page(%{attrs: attrs2, project: project, scope: scope})

      assert page1.project_id == project.id
      assert page2.project_id == project.id
      assert page1.slug != page2.slug
      assert page1.id != page2.id
    end

    test "handles nil attrs gracefully" do
      user = WeCraft.AccountsFixtures.user_fixture()
      scope = WeCraft.AccountsFixtures.user_scope_fixture(user)
      project = ProjectsFixtures.project_fixture(%{owner: user})

      assert_raise Ecto.CastError, fn ->
        CreatePageUseCase.create_page(%{attrs: nil, project: project, scope: scope})
      end
    end

    test "creates page with minimal valid attributes" do
      user = WeCraft.AccountsFixtures.user_fixture()
      scope = WeCraft.AccountsFixtures.user_scope_fixture(user)
      project = ProjectsFixtures.project_fixture(%{owner: user})

      attrs = %{
        # Minimal title
        title: "T",
        # Minimal slug
        slug: "t",
        project_id: project.id
      }

      assert {:ok, %Page{} = page} =
               CreatePageUseCase.create_page(%{attrs: attrs, project: project, scope: scope})

      assert page.title == "T"
      assert page.slug == "t"
    end
  end
end
