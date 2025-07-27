defmodule WeCraft.Pages.UseCases.ListProjectPagesUseCase do
  @moduledoc """
  Use case for listing pages within a project.
  This use case retrieves all pages associated with a specific project.
  """
  alias WeCraft.Pages.Infrastructure.Ecto.PageRepositoryEcto

  def list_project_pages(%{project: project, scope: _scope}) do
    {:ok, PageRepositoryEcto.list_project_pages(project.id)}
  end
end
