defmodule WeCraft.Pages do
  @moduledoc """
  LiveView for creating a new page in a project.
  """

  alias WeCraft.Pages.UseCases.{CreatePageUseCase, GetPageUseCase, ListProjectPagesUseCase}

  defdelegate create_page(attrs), to: CreatePageUseCase

  defdelegate get_page(attrs), to: GetPageUseCase

  defdelegate list_project_pages(project), to: ListProjectPagesUseCase
end
