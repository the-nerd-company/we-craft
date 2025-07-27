defmodule WeCraft.Projects.ProjectTest do
  @moduledoc """
  Tests for the WeCraft.Projects.Project schema.
  """

  use ExUnit.Case
  alias WeCraft.Projects.Project

  test "changeset validates technical tags" do
    # Create a basic valid project
    valid_attrs = %{
      title: "Test Project",
      description: "A project for testing",
      status: :idea,
      visibility: :public,
      tags: ["javascript", "typescript", "elixir"]
    }

    changeset = Project.changeset(%Project{}, valid_attrs)
    assert changeset.valid?

    # Check that tags are normalized to lowercase
    assert Ecto.Changeset.get_change(changeset, :tags) == ["javascript", "typescript", "elixir"]

    # Test with invalid tags
    invalid_attrs = Map.put(valid_attrs, :tags, ["javascript", "not_a_real_tag", "elixir"])
    changeset = Project.changeset(%Project{}, invalid_attrs)
    refute changeset.valid?
    assert {"contains invalid technical tags: not_a_real_tag", _} = changeset.errors[:tags]

    # Test with uppercase tags (should be normalized)
    uppercase_attrs = Map.put(valid_attrs, :tags, ["JAVASCRIPT", "TypeScript"])
    changeset = Project.changeset(%Project{}, uppercase_attrs)
    assert changeset.valid?
    assert Ecto.Changeset.get_change(changeset, :tags) == ["javascript", "typescript"]
  end
end
