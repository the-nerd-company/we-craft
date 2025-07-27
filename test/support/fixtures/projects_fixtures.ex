defmodule WeCraft.ProjectsFixtures do
  @moduledoc """
  This module provides test fixtures for the Projects context.
  """

  alias WeCraft.AccountsFixtures
  alias WeCraft.FixtureHelper
  alias WeCraft.Projects.NeedsTags
  alias WeCraft.Projects.Project
  alias WeCraft.Projects.TechnicalTags

  def project_fixture(attrs \\ %{}) do
    owner = attrs[:owner] || AccountsFixtures.user_fixture()

    # Get all available tags and select a random subset (between 1 and 5 tags)
    FixtureHelper.insert_entity(
      Project,
      %{
        title: Faker.Pokemon.name(),
        description: Faker.Lorem.sentence(),
        tags: Enum.take_random(TechnicalTags.all_tags(), Enum.random(2..10)),
        needs: Enum.take_random(NeedsTags.all_needs(), Enum.random(1..2)),
        status: :idea,
        visibility: :public,
        owner_id: owner.id
      },
      Map.drop(attrs, [:owner])
    )
  end
end
