defmodule WeCraft.Projects.Follower do
  @moduledoc """
  A module representing a follower relationship between a user and a project.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "followers" do
    belongs_to :user, WeCraft.Accounts.User
    belongs_to :project, WeCraft.Projects.Project

    timestamps()
  end

  @doc false
  def changeset(follower, attrs) do
    follower
    |> cast(attrs, [:user_id, :project_id])
    |> validate_required([:user_id, :project_id])
    |> unique_constraint([:user_id, :project_id], name: :followers_user_id_project_id_index)
  end
end
