defmodule WeCraft.MilestonesFixtures do
  @moduledoc """
  This module provides test fixtures for the Milestones context.
  """

  alias WeCraft.FixtureHelper
  alias WeCraft.Milestones.{Milestone, Task}
  alias WeCraft.ProjectsFixtures

  def milestone_fixture(attrs \\ %{}) do
    project = attrs[:project] || ProjectsFixtures.project_fixture()

    # Get all available tags and select a random subset (between 1 and 5 tags)
    FixtureHelper.insert_entity(
      Milestone,
      %{
        title: Faker.Pokemon.name(),
        description: Faker.Lorem.sentence(),
        status: Milestone.all_status() |> Enum.random(),
        project_id: project.id
      },
      Map.drop(attrs, [])
    )
  end

  def task_fixture(attrs \\ %{}) do
    milestone = attrs[:milestone] || milestone_fixture()

    # Get all available tags and select a random subset (between 1 and 5 tags)
    FixtureHelper.insert_entity(
      Task,
      %{
        title: Faker.Pokemon.name(),
        description: Faker.Lorem.sentence(),
        status: Task.all_status() |> Enum.random(),
        milestone_id: milestone.id
      },
      Map.drop(attrs, [])
    )
  end
end
