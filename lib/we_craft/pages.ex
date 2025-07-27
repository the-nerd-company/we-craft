defmodule WeCraft.Pages do
  @moduledoc """
  LiveView for creating a new page in a project.
  """
  use WeCraftWeb, :live_view

  alias WeCraft.Pages.UseCases.{CreatePageUseCase, ListProjectPagesUseCase}

  defdelegate create_page(attrs), to: CreatePageUseCase
  defdelegate list_project_pages(project), to: ListProjectPagesUseCase
end
