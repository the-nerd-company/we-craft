defmodule WeCraft.FixtureHelper do
  @moduledoc """
  This module provides helper functions for inserting entities in tests.
  """

  alias WeCraft.Repo

  def insert_entity(module, default_attrs, attrs) do
    {:ok, entity} =
      struct(module)
      |> module.changeset(Map.merge(default_attrs, attrs))
      |> Repo.insert()

    entity
  end
end
