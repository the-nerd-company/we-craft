defmodule WeCraft.Projects.NeedsTags do
  @moduledoc """
  Provides a list of predefined needs tags for projects.
  """
  @needs_values [
    "frontend",
    "backend",
    "devops",
    "ui/ux",
    "mobile",
    "data",
    "testing",
    "documentation",
    "security",
    "performance",
    "marketing",
    "community management",
    "business development",
    "sales",
    "content creation"
  ]

  def all_needs do
    @needs_values
  end
end
