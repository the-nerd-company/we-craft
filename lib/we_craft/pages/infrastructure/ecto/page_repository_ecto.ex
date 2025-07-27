defmodule WeCraft.Pages.Infrastructure.Ecto.PageRepositoryEcto do
  @moduledoc """
  Ecto-based implementation of the MilestoneRepository.
  This module interacts with the database to manage project milestones.
  """

  alias WeCraft.Pages.Page
  alias WeCraft.Repo

  import Ecto.Query

  def create_page(attrs) do
    %Page{}
    |> Page.changeset(attrs)
    |> Repo.insert()
  end

  def get_page(id) do
    Repo.get(Page, id) |> Repo.preload(:project)
  end

  def update_page(%Page{} = page, attrs) do
    page
    |> Page.changeset(attrs)
    |> Repo.update()
  end

  def list_project_pages(project_id) do
    Repo.all(
      from p in Page,
        where: p.project_id == ^project_id and is_nil(p.parent_page_id),
        order_by: [asc: p.title]
    )
  end
end
