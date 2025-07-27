defmodule WeCraft.Pages.Page do
  @moduledoc """
  Module representing a page in the WeCraft application.
  This module is used to handle page-related functionalities.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias WeCraft.Projects.Project

  schema "pages" do
    field :title, :string
    field :slug, :string
    field :parent_page_id, :integer
    field :blocks, {:array, :map}

    belongs_to :project, Project
    belongs_to :parent_page, __MODULE__, foreign_key: :parent_id
    has_many :children, __MODULE__, foreign_key: :parent_page_id

    timestamps()
  end

  @doc false
  def changeset(page, attrs) do
    page
    |> cast(attrs, [:title, :slug, :project_id, :blocks, :parent_id, :parent_page_id])
    |> validate_required([:title, :slug, :project_id])
    |> unique_constraint(:slug)
  end
end
