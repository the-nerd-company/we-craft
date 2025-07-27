defmodule WeCraft.Projects.TechnicalTags do
  @moduledoc """
  Defines and manages technical tags for projects.
  """

  # Frontend technologies
  @frontend_tags [
    "javascript",
    "typescript",
    "react",
    "vue",
    "angular",
    "svelte",
    "html",
    "css",
    "sass",
    "tailwind",
    "bootstrap"
  ]

  # Backend technologies
  @backend_tags [
    "elixir",
    "phoenix",
    "ruby",
    "rails",
    "python",
    "django",
    "flask",
    "node",
    "express",
    "java",
    "spring",
    "php",
    "laravel",
    "go",
    "rust",
    "c#",
    ".net"
  ]

  # Database technologies
  @database_tags [
    "postgresql",
    "mysql",
    "mongodb",
    "redis",
    "sqlite",
    "elasticsearch",
    "firebase",
    "dynamodb"
  ]

  # DevOps and infrastructure
  @devops_tags [
    "docker",
    "kubernetes",
    "aws",
    "gcp",
    "azure",
    "ci/cd",
    "github-actions",
    "gitlab-ci",
    "terraform",
    "ansible"
  ]

  # Mobile technologies
  @mobile_tags [
    "swift",
    "kotlin",
    "flutter",
    "react-native",
    "ionic"
  ]

  @doc """
  Returns all available technical tags grouped by category.
  """
  def all_tags_by_category do
    %{
      frontend: @frontend_tags,
      backend: @backend_tags,
      database: @database_tags,
      devops: @devops_tags,
      mobile: @mobile_tags
    }
  end

  @doc """
  Returns all available technical tags as a flat list.
  """
  def all_tags do
    @frontend_tags ++ @backend_tags ++ @database_tags ++ @devops_tags ++ @mobile_tags
  end

  @doc """
  Checks if a tag is valid (exists in our predefined list).
  """
  def valid_tag?(tag) when is_binary(tag) do
    String.downcase(tag) in all_tags()
  end

  def valid_tag?(_), do: false

  @doc """
  Filter a list of tags to only include valid ones.
  """
  def filter_valid_tags(tags) when is_list(tags) do
    Enum.filter(tags, &valid_tag?/1)
  end

  def filter_valid_tags(_), do: []
end
