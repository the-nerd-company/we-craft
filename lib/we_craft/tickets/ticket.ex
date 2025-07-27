defmodule WeCraft.Tickets.Ticket do
  @moduledoc """
  Represents a ticket in the system.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias WeCraft.CRM.Customer
  alias WeCraft.Projects.Project

  @customer_ticket_type [:feature_request, :bug_report, :enhancement]

  @ticket_status [:new, :done, :in_progress, :rejected]

  def get_customer_ticket_types, do: @customer_ticket_type

  def get_ticket_status, do: @ticket_status

  schema "tickets" do
    field :title, :string
    field :type, Ecto.Enum, values: @customer_ticket_type
    field :description, :string
    field :status, Ecto.Enum, values: @ticket_status
    field :priority, :integer
    belongs_to :project, Project
    belongs_to :customer, Customer
    timestamps()
  end

  @doc false
  def changeset(ticket, attrs) do
    ticket
    |> cast(attrs, [:title, :description, :type, :status, :priority, :project_id, :customer_id])
    |> validate_required([:title, :description, :type, :status, :priority, :project_id])
  end
end
