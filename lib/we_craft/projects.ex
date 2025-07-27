defmodule WeCraft.Projects do
  @moduledoc """
  The Projects context.
  """

  defdelegate list_project_events(attrs), to: WeCraft.Projects.UseCases.ListProjectEventsUseCase

  defdelegate list_user_projects(attrs), to: WeCraft.Projects.UseCases.ListUserProjectsUseCase

  defdelegate list_projects(attrs), to: WeCraft.Projects.UseCases.ListProjectsUseCase

  defdelegate get_project(attrs), to: WeCraft.Projects.UseCases.GetProjectUseCase

  defdelegate create_project(attrs), to: WeCraft.Projects.UseCases.CreateProjectUseCase

  defdelegate update_project(attrs), to: WeCraft.Projects.UseCases.UpdateProjectUseCase

  defdelegate follow_project(attrs), to: WeCraft.Projects.UseCases.FollowProjectUseCase

  defdelegate unfollow_project(attrs), to: WeCraft.Projects.UseCases.UnfollowProjectUseCase

  defdelegate check_following_status(attrs),
    to: WeCraft.Projects.UseCases.CheckFollowingStatusUseCase

  defdelegate get_feed(attrs), to: WeCraft.Projects.UseCases.GetFeedUseCase

  defdelegate get_project_followers_count(attrs),
    to: WeCraft.Projects.UseCases.GetProjectFollowersCountUseCase

  @doc """
  Search for projects by tags, title, business domains, and/or status.

  ## Parameters
    * `params` - A map of search parameters that can include:
      * `:tags` - List of tags to filter by (optional)
      * `:title` - Title search string (optional)
      * `:business_domains` - List of business domains to filter by (optional)
      * `:status` - Project status to filter by (optional)

  ## Examples
      search_projects(%{tags: ["elixir", "phoenix"]})
      search_projects(%{title: "app"})
      search_projects(%{tags: ["javascript"], title: "app"})
      search_projects(%{business_domains: ["fintech"]})
      search_projects(%{status: :live})
  """
  def search_projects(params) do
    list_projects(params)
  end

  @doc """
  Returns a list of all available technical tags.
  """
  defdelegate all_technical_tags(), to: WeCraft.Projects.TechnicalTags, as: :all_tags

  @doc """
  Returns all technical tags grouped by category.
  """
  defdelegate all_technical_tags_by_category(),
    to: WeCraft.Projects.TechnicalTags,
    as: :all_tags_by_category

  @doc """
  Validates if a tag is in the predefined list of technical tags.
  """
  defdelegate valid_technical_tag?(tag), to: WeCraft.Projects.TechnicalTags, as: :valid_tag?
end
