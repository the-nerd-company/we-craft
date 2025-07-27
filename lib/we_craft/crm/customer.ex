defmodule WeCraft.CRM.Customer do
  @moduledoc """
  A customer in the CRM system.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias WeCraft.Projects.Project

  schema "customers" do
    field :email, :string
    field :external_id, :string
    field :comment, :string
    field :name, :string
    field :metadata, :map
    field :tags, {:array, :string}
    belongs_to :project, Project

    timestamps()
  end

  def changeset(customer, attrs) do
    customer
    |> cast(attrs, [:email, :name, :external_id, :metadata, :project_id, :tags, :comment])
    |> validate_required([:email, :name, :external_id, :project_id])
  end
end
