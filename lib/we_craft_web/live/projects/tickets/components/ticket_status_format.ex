defmodule WeCraftWeb.Projects.Tickets.Components.TicketStatusFormat do
  @moduledoc """
  A module for formatting ticket status and type.
  """

  def format_ticket_status(status) do
    status |> format_atom()
  end

  def format_ticket_type(status) do
    status |> format_atom()
  end

  defp format_atom(atom) do
    atom
    |> to_string()
    |> String.replace("_", " ")
    |> String.split()
    |> Enum.map_join(" ", &String.capitalize/1)
  end
end
