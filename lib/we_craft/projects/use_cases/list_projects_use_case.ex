defmodule WeCraft.Projects.UseCases.ListProjectsUseCase do
  @moduledoc """
  This module provides the use case for listing projects.
  """

  alias WeCraft.Projects.Infrastructure.Ecto.ProjectRepositoryEcto

  @doc """
  Lists all projects.

  ## Parameters
    * `attrs` - A map of attributes that can include:
      * `:scope` - Current scope (optional)
      * `:tags` - List of tags to filter by (optional)
      * `:title` - Title search string (optional)
      * `:business_domains` - List of business domains to filter by (optional)
      * `:status` - Project status to filter by (optional)

  ## Examples
      list_projects(%{})
      list_projects(%{tags: ["elixir", "phoenix"]})
      list_projects(%{title: "app"})
      list_projects(%{business_domains: ["fintech"]})
      list_projects(%{status: :live})
  """
  # Handle function with all search parameters
  def list_projects(%{tags: tags, title: title, business_domains: domains, status: status})
      when is_list(tags) and is_binary(title) and is_list(domains) and not is_nil(status) do
    {:ok,
     ProjectRepositoryEcto.search_projects(%{
       tags: tags,
       title: title,
       business_domains: domains,
       status: status
     })}
  end

  # Handle various combinations of search parameters
  def list_projects(%{tags: tags, title: title, business_domains: domains})
      when is_list(tags) and is_binary(title) and is_list(domains) do
    {:ok,
     ProjectRepositoryEcto.search_projects(%{
       tags: tags,
       title: title,
       business_domains: domains
     })}
  end

  def list_projects(%{tags: tags, title: title, status: status})
      when is_list(tags) and is_binary(title) and not is_nil(status) do
    {:ok,
     ProjectRepositoryEcto.search_projects(%{
       tags: tags,
       title: title,
       status: status
     })}
  end

  def list_projects(%{tags: tags, business_domains: domains, status: status})
      when is_list(tags) and is_list(domains) and not is_nil(status) do
    {:ok,
     ProjectRepositoryEcto.search_projects(%{
       tags: tags,
       business_domains: domains,
       status: status
     })}
  end

  def list_projects(%{title: title, business_domains: domains, status: status})
      when is_binary(title) and is_list(domains) and not is_nil(status) do
    {:ok,
     ProjectRepositoryEcto.search_projects(%{
       title: title,
       business_domains: domains,
       status: status
     })}
  end

  def list_projects(%{tags: tags, title: title}) when is_list(tags) and is_binary(title) do
    {:ok, ProjectRepositoryEcto.search_projects(%{tags: tags, title: title})}
  end

  def list_projects(%{tags: tags, business_domains: domains})
      when is_list(tags) and is_list(domains) do
    {:ok, ProjectRepositoryEcto.search_projects(%{tags: tags, business_domains: domains})}
  end

  def list_projects(%{tags: tags, status: status}) when is_list(tags) and not is_nil(status) do
    {:ok, ProjectRepositoryEcto.search_projects(%{tags: tags, status: status})}
  end

  def list_projects(%{title: title, business_domains: domains})
      when is_binary(title) and is_list(domains) do
    {:ok, ProjectRepositoryEcto.search_projects(%{title: title, business_domains: domains})}
  end

  def list_projects(%{title: title, status: status})
      when is_binary(title) and not is_nil(status) do
    {:ok, ProjectRepositoryEcto.search_projects(%{title: title, status: status})}
  end

  def list_projects(%{business_domains: domains, status: status})
      when is_list(domains) and not is_nil(status) do
    {:ok, ProjectRepositoryEcto.search_projects(%{business_domains: domains, status: status})}
  end

  def list_projects(%{tags: tags}) when is_list(tags) do
    {:ok, ProjectRepositoryEcto.search_projects(%{tags: tags})}
  end

  def list_projects(%{title: title}) when is_binary(title) do
    {:ok, ProjectRepositoryEcto.search_projects(%{title: title})}
  end

  def list_projects(%{business_domains: domains}) when is_list(domains) do
    {:ok, ProjectRepositoryEcto.search_projects(%{business_domains: domains})}
  end

  def list_projects(%{status: status}) when not is_nil(status) do
    {:ok, ProjectRepositoryEcto.search_projects(%{status: status})}
  end

  def list_projects(%{}) do
    {:ok, ProjectRepositoryEcto.list_projects()}
  end
end
