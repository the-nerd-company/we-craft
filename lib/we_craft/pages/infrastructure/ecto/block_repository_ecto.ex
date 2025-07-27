defmodule WeCraft.Pages.Infrastructure.Ecto.BlockRepositoryEcto do
  @moduledoc """
  Ecto-based implementation of the BlockRepository.
  This module interacts with the database to manage page blocks.
  """

  alias WeCraft.Pages.Block
  alias WeCraft.Repo

  def create_block(attrs) do
    %Block{}
    |> Block.changeset(attrs)
    |> Repo.insert()
  end

  def update_block(%Block{} = block, attrs) do
    block
    |> Block.changeset(attrs)
    |> Repo.update()
  end

  def delete_block(%Block{} = block) do
    Repo.delete(block)
  end
end
