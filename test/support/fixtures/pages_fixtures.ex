defmodule WeCraft.PagesFixtures do
  @moduledoc """
  This module provides test fixtures for the Pages context.
  """

  alias WeCraft.FixtureHelper
  alias WeCraft.Pages.{Block, Page}
  alias WeCraft.ProjectsFixtures

  def page_fixture(attrs \\ %{}) do
    project = attrs[:project] || ProjectsFixtures.project_fixture()

    FixtureHelper.insert_entity(
      Page,
      %{
        title: Faker.Lorem.words(2..3) |> Enum.join(" "),
        content: Faker.Lorem.sentence(),
        slug: Faker.Lorem.word() <> "-" <> Integer.to_string(System.unique_integer([:positive])),
        project_id: project.id
      },
      Map.drop(attrs, [:project])
    )
  end

  def page_with_parent_fixture(attrs \\ %{}) do
    parent_page = attrs[:parent_page] || page_fixture()
    project_id = attrs[:project_id] || parent_page.project_id

    FixtureHelper.insert_entity(
      Page,
      %{
        title: Faker.Lorem.words(2..3) |> Enum.join(" "),
        content: Faker.Lorem.sentence(),
        slug: Faker.Lorem.word() <> "-" <> Integer.to_string(System.unique_integer([:positive])),
        project_id: project_id,
        parent_page_id: parent_page.id,
        parent_id: parent_page.id
      },
      Map.drop(attrs, [:parent_page, :project_id])
    )
  end

  def block_fixture(attrs \\ %{}) do
    page = attrs[:page] || page_fixture()

    FixtureHelper.insert_entity(
      Block,
      %{
        type: attrs[:type] || Enum.random([:text, :heading, :checklist, :image]),
        content: %{
          "text" => Faker.Lorem.paragraph(),
          "level" => Enum.random(1..6)
        },
        position: attrs[:position] || Enum.random(1..10),
        page_id: page.id
      },
      Map.drop(attrs, [:page])
    )
  end

  def block_with_parent_fixture(attrs \\ %{}) do
    parent_block = attrs[:parent_block] || block_fixture()
    page_id = attrs[:page_id] || parent_block.page_id

    FixtureHelper.insert_entity(
      Block,
      %{
        type: attrs[:type] || :text,
        content: %{
          "text" => Faker.Lorem.sentence()
        },
        position: attrs[:position] || Enum.random(1..10),
        page_id: page_id,
        parent_id: parent_block.id
      },
      Map.drop(attrs, [:parent_block, :page_id])
    )
  end
end
