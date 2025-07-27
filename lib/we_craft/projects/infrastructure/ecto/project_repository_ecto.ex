defmodule WeCraft.Projects.Infrastructure.Ecto.ProjectRepositoryEcto do
  @moduledoc """
  Ecto implementation of the ProjectRepository.
  """

  import Ecto.Query, warn: false

  alias WeCraft.Projects.{Follower, Project}
  alias WeCraft.Repo

  def get_project(id) do
    Repo.get(Project, id) |> Repo.preload(:owner)
  end

  def list_projects do
    from(p in Project,
      left_join: f in Follower,
      on: f.project_id == p.id,
      group_by: p.id,
      select: %Project{
        id: p.id,
        title: p.title,
        description: p.description,
        repository_url: p.repository_url,
        tags: p.tags,
        needs: p.needs,
        business_domains: p.business_domains,
        status: p.status,
        visibility: p.visibility,
        owner_id: p.owner_id,
        inserted_at: p.inserted_at,
        updated_at: p.updated_at,
        followers_count: count(f.id)
      }
    )
    |> Repo.all()
    |> Repo.preload(:owner)
  end

  def list_projects_by_user(user_id) do
    Repo.all(from p in Project, where: p.owner_id == ^user_id)
  end

  @doc """
  Search projects by tags, title, business domains and status.

  ## Options
    * `:tags` - A list of tags to filter by. Projects containing ANY of these tags will be returned.
    * `:title` - A string to search within project titles (case insensitive partial match).
    * `:business_domains` - A list of business domains to filter by. Projects containing ANY of these domains will be returned.
    * `:status` - A project status or list of statuses to filter by.

  ## Examples
      search_projects(%{tags: ["elixir", "phoenix"]})
      search_projects(%{title: "saas"})
      search_projects(%{tags: ["javascript"], title: "app"})
      search_projects(%{business_domains: ["fintech", "healthtech"]})
      search_projects(%{status: :live})
      search_projects(%{status: [:idea, :in_dev]})
  """
  def search_projects(params) do
    Project
    |> filter_by_tags(params[:tags])
    |> filter_by_title(params[:title])
    |> filter_by_business_domains(params[:business_domains])
    |> filter_by_status(params[:status])
    |> join(:left, [p], f in Follower, on: f.project_id == p.id)
    |> group_by([p], p.id)
    |> select([p, f], %Project{
      id: p.id,
      title: p.title,
      description: p.description,
      repository_url: p.repository_url,
      tags: p.tags,
      needs: p.needs,
      business_domains: p.business_domains,
      status: p.status,
      visibility: p.visibility,
      owner_id: p.owner_id,
      inserted_at: p.inserted_at,
      updated_at: p.updated_at,
      followers_count: count(f.id)
    })
    |> Repo.all()
    |> Repo.preload(:owner)
  end

  # Apply tag filtering if tags parameter is present
  defp filter_by_tags(query, nil), do: query
  defp filter_by_tags(query, []), do: query

  defp filter_by_tags(query, tags) when is_list(tags) do
    # Returns projects that contain ANY of the specified tags (OR condition)
    from p in query, where: fragment("? && ?", p.tags, ^tags)
  end

  # Apply title filtering if title parameter is present
  defp filter_by_title(query, nil), do: query
  defp filter_by_title(query, ""), do: query

  defp filter_by_title(query, title) when is_binary(title) do
    title_pattern = "%#{String.downcase(title)}%"
    from p in query, where: fragment("lower(?) LIKE ?", p.title, ^title_pattern)
  end

  # Apply business domains filtering
  defp filter_by_business_domains(query, nil), do: query
  defp filter_by_business_domains(query, []), do: query

  defp filter_by_business_domains(query, domains) when is_list(domains) do
    # Returns projects that contain ANY of the specified business domains (OR condition)
    from p in query, where: fragment("? && ?", p.business_domains, ^domains)
  end

  # Apply status filtering
  defp filter_by_status(query, nil), do: query
  defp filter_by_status(query, []), do: query

  # Handle single status value
  defp filter_by_status(query, status) when is_atom(status) do
    from p in query, where: p.status == ^status
  end

  # Handle multiple status values
  defp filter_by_status(query, statuses) when is_list(statuses) do
    from p in query, where: p.status in ^statuses
  end

  def update_project(%Project{} = project, attrs) do
    project
    |> Project.changeset(attrs)
    |> Repo.update()
  end

  def create_project(attrs) do
    %Project{}
    |> Project.changeset(attrs)
    |> Repo.insert()
  end
end
