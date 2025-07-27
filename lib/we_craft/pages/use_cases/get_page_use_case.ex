defmodule WeCraft.Pages.UseCases.GetPageUseCase do
  @moduledoc """
  Use case for retrieving a page.
  """
  alias WeCraft.Pages.Infrastructure.Ecto.PageRepositoryEcto
  alias WeCraft.Pages.PagePermissions

  def get_page(%{page_id: page_id, scope: scope}) do
    page = PageRepositoryEcto.get_page(page_id)

    if PagePermissions.can_view_page?(%{page: page, scope: scope}) do
      {:ok, page}
    else
      {:error, :unauthorized}
    end
  end
end
