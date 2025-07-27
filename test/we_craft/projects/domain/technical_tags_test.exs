defmodule WeCraft.Projects.TechnicalTagsTest do
  @moduledoc """
  Tests for the WeCraft.Projects.TechnicalTags module.
  """

  use ExUnit.Case

  alias WeCraft.Projects
  alias WeCraft.Projects.TechnicalTags

  test "all_tags returns a list of all technical tags" do
    tags = Projects.all_technical_tags()

    # Basic checks
    assert is_list(tags)
    assert length(tags) > 0
    assert "javascript" in tags
    assert "typescript" in tags
    assert "elixir" in tags
  end

  test "all_tags_by_category returns tags grouped by category" do
    tags_by_category = Projects.all_technical_tags_by_category()

    # Check structure
    assert is_map(tags_by_category)
    assert Map.has_key?(tags_by_category, :frontend)
    assert Map.has_key?(tags_by_category, :backend)
    assert Map.has_key?(tags_by_category, :database)

    # Check some values
    assert "javascript" in tags_by_category.frontend
    assert "elixir" in tags_by_category.backend
    assert "postgresql" in tags_by_category.database
  end

  test "valid_tag? validates tags correctly" do
    # Valid tags
    assert Projects.valid_technical_tag?("javascript")
    assert Projects.valid_technical_tag?("elixir")
    # Case insensitive
    assert Projects.valid_technical_tag?("TYPESCRIPT")

    # Invalid tags
    refute Projects.valid_technical_tag?("not_a_real_language")
    refute Projects.valid_technical_tag?(123)
    refute Projects.valid_technical_tag?(nil)
  end

  test "filter_valid_tags returns only valid tags" do
    tags = ["javascript", "not_a_tag", "typescript", 123, "elixir"]
    filtered = TechnicalTags.filter_valid_tags(tags)

    assert filtered == ["javascript", "typescript", "elixir"]
  end
end
