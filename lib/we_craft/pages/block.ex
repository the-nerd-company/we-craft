defmodule WeCraft.Pages.Block do
  @moduledoc """
  Module representing a block in a page.
  This module is used to handle block-related functionalities.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias WeCraft.Pages.Page

  @block_types [:text, :heading, :checklist, :image, :video]

  schema "blocks" do
    field :type, Ecto.Enum, values: @block_types
    field :content, :map
    field :position, :integer

    belongs_to :page, Page
    belongs_to :parent_block, __MODULE__, foreign_key: :parent_id
    has_many :children, __MODULE__, foreign_key: :parent_id

    timestamps()
  end

  @doc false
  def changeset(block, attrs) do
    block
    |> cast(attrs, [:type, :content, :position, :page_id, :parent_id])
    |> validate_required([:type, :content, :position, :page_id])
  end
end
