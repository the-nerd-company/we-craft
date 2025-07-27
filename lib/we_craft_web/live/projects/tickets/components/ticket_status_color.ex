defmodule WeCraftWeb.Projects.Tickets.Components.TicketStatusColor do
  @moduledoc """
  Helper functions for mapping ticket status to daisyUI badge colors.
  """
  def status_color(:new), do: "primary"
  def status_color(:in_progress), do: "warning"
  def status_color(:done), do: "success"
  def status_color(:rejected), do: "error"
  def status_color(_), do: "neutral"
end
