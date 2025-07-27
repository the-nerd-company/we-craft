defmodule WeCraftWeb.Projects.Components.ProjectStatusBadge do
  @moduledoc """
  Component to display the status of a project as a badge.
  """
  use Phoenix.Component

  alias WeCraft.Projects.Project

  attr :project, :map, required: true

  @doc """
  Renders a badge indicating the project's status.
  """
  def project_status_badge_xs(assigns) do
    ~H"""
    <span class={"badge badge-xs #{status_badge_class(@project.status)}"}>
      {Project.status_display(@project.status)}
    </span>
    """
  end

  def project_status_badge(assigns) do
    ~H"""
    <span class={"badge badge-primary #{status_badge_class(@project.status)}"}>
      {Project.status_display(@project.status)}
    </span>
    """
  end

  defp status_badge_class(:idea), do: "badge-info"
  defp status_badge_class(:in_dev), do: "badge-warning"
  defp status_badge_class(:private_beta), do: "badge-secondary"
  defp status_badge_class(:public_beta), do: "badge-accent"
  defp status_badge_class(:live), do: "badge-success"
  defp status_badge_class(_), do: "badge-neutral"
end
