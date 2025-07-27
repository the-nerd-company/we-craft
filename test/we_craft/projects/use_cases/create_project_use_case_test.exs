defmodule WeCraft.Projects.UseCases.CreateProjectUseCaseTest do
  @moduledoc """
  Tests for the CreateProjectUseCase module.
  """
  use WeCraft.DataCase

  alias WeCraft.Chats.Chat
  alias WeCraft.Projects
  alias WeCraft.Projects.Project
  alias WeCraft.Repo

  import WeCraft.AccountsFixtures

  describe "create_project/1" do
    setup do
      %{user: user_fixture()}
    end

    test "creates a project with valid data", %{user: user} do
      valid_attrs = %{
        title: "Test Project",
        description: "A test project description",
        tags: ["elixir", "phoenix"],
        needs: ["frontend", "backend"],
        status: :idea,
        visibility: :public,
        owner_id: user.id
      }

      assert {:ok, %Project{} = project} =
               Projects.create_project(%{attrs: valid_attrs})

      assert project.title == "Test Project"
      assert project.description == "A test project description"
      assert project.tags == ["elixir", "phoenix"]
      assert project.needs == ["frontend", "backend"]
      assert project.status == :idea
      assert project.visibility == :public
      assert project.owner_id == user.id

      # Verify that a main chat was created for the project
      chat = Repo.get_by(Chat, project_id: project.id)
      assert chat
      assert chat.is_main == true
      assert chat.project_id == project.id
    end

    test "fails with invalid project data", %{user: user} do
      # Missing required fields
      invalid_attrs = %{
        # title is missing
        description: "A test project description",
        tags: ["elixir", "phoenix"],
        needs: ["frontend", "backend"],
        status: :idea,
        visibility: :public,
        owner_id: user.id
      }

      assert {:error, %Ecto.Changeset{}} =
               Projects.create_project(%{attrs: invalid_attrs})

      # No chat should be created
      assert Repo.aggregate(Chat, :count) == 0
    end

    test "creates a project with minimum required fields", %{user: user} do
      min_attrs = %{
        title: "Minimal Project",
        description: "A minimal project description",
        status: :idea,
        visibility: :public,
        owner_id: user.id
      }

      assert {:ok, %Project{} = project} =
               Projects.create_project(%{attrs: min_attrs})

      assert project.title == "Minimal Project"
      assert project.tags == []
      assert project.needs == []

      # Verify that a main chat was created for the project
      chat = Repo.get_by(Chat, project_id: project.id)
      assert chat
      assert chat.is_main == true
    end

    test "creates a project with a different status", %{user: user} do
      live_attrs = %{
        title: "Live Project",
        description: "A live project description",
        tags: ["elixir", "phoenix"],
        status: :live,
        visibility: :public,
        owner_id: user.id
      }

      assert {:ok, %Project{} = project} =
               Projects.create_project(%{attrs: live_attrs})

      assert project.status == :live

      # Verify that a main chat was created for the project
      chat = Repo.get_by(Chat, project_id: project.id)
      assert chat
      assert chat.is_main == true
    end
  end
end
