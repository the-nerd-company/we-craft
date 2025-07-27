defmodule WeCraft.Milestones.Infrastructure.Ecto.MilestoneRepositoryEctoTest do
  @moduledoc """
  Tests for the Ecto-based MilestoneRepository.
  This module contains tests to ensure the functionality of the MilestoneRepositoryEcto.
  """
  use WeCraft.DataCase, async: true

  import WeCraft.ProjectsFixtures
  import WeCraft.MilestonesFixtures

  alias WeCraft.Milestones.Infrastructure.Ecto.MilestoneRepositoryEcto
  alias WeCraft.Milestones.Milestone

  describe "create_milestone/1" do
    test "successfully creates a milestone" do
      project = project_fixture()

      attrs = %{
        title: "Test Milestone",
        description: "This is a test milestone.",
        due_date: ~U[2023-12-31 23:59:59Z],
        status: Milestone.all_status() |> Enum.random(),
        project_id: project.id
      }

      assert {:ok, %Milestone{} = milestone} = MilestoneRepositoryEcto.create_milestone(attrs)
      assert milestone.title == attrs.title
      assert milestone.description == attrs.description
    end
  end

  describe "update_milestone/2" do
    test "successfully updates a milestone" do
      existing_milestone = milestone_fixture()

      attrs = %{title: "Updated Title", description: "Updated Description"}

      assert {:ok, %Milestone{} = updated_milestone} =
               MilestoneRepositoryEcto.update_milestone(existing_milestone, attrs)

      assert updated_milestone.title == attrs.title
      assert updated_milestone.description == attrs.description
    end
  end
end
