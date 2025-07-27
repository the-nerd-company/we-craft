defmodule WeCraft.Pages.UseCases.CreatePageUseCase do
  @moduledoc """
  Use case for creating a new page.
  This use case handles the creation of a page with the provided attributes.
  It validates the attributes and interacts with the PageRepository to persist the page.
  """
  alias WeCraft.Pages.Infrastructure.Ecto.PageRepositoryEcto
  alias WeCraft.Pages.PagePermissions

  def create_page(%{attrs: attrs, project: project, scope: scope}) do
    if PagePermissions.can_create_page?(%{project: project, scope: scope}) do
      PageRepositoryEcto.create_page(attrs)
    else
      {:error, :unauthorized}
    end
  end
end
