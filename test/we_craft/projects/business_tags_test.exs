defmodule WeCraft.Projects.BusinessTagsTest do
  @moduledoc """
  Tests for the BusinessTags module.
  """
  use ExUnit.Case, async: true

  alias WeCraft.Projects.BusinessTags

  describe "all_tags/0" do
    test "returns all business tags as a list of strings" do
      tags = BusinessTags.all_tags()
      assert is_list(tags)
      assert Enum.all?(tags, &is_binary/1)
      # Should include some known tags
      assert "saas" in tags
      assert "fintech" in tags
      assert "ai" in tags
      assert "developers" in tags
      # Should not be empty
      assert length(tags) > 0
    end
  end

  describe "categorized_tags/0" do
    test "returns a map of categories to tag lists" do
      cat_tags = BusinessTags.categorized_tags()
      assert is_map(cat_tags)
      # Should have expected categories
      for cat <- ["Business Models", "Industry Sectors", "Application Areas", "Target Users"] do
        assert Map.has_key?(cat_tags, cat)
        assert is_list(cat_tags[cat])
        assert Enum.all?(cat_tags[cat], &is_binary/1)
      end

      # Should include some known tags in categories
      assert "saas" in cat_tags["Business Models"]
      assert "fintech" in cat_tags["Industry Sectors"]
      assert "ai" in cat_tags["Application Areas"]
      assert "developers" in cat_tags["Target Users"]
    end
  end
end
