defmodule WeCraftWeb.Projects.Tickets.Components.TicketStatusColorTest do
  @moduledoc """
  Tests for the TicketStatusColor module.
  """
  use ExUnit.Case, async: true

  alias WeCraftWeb.Projects.Tickets.Components.TicketStatusColor

  describe ".status_color/1" do
    test "returns 'primary' for :new" do
      assert TicketStatusColor.status_color(:new) == "primary"
    end

    test "returns 'warning' for :in_progress" do
      assert TicketStatusColor.status_color(:in_progress) == "warning"
    end

    test "returns 'success' for :done" do
      assert TicketStatusColor.status_color(:done) == "success"
    end

    test "returns 'error' for :rejected" do
      assert TicketStatusColor.status_color(:rejected) == "error"
    end

    test "returns 'neutral' for unknown status" do
      assert TicketStatusColor.status_color(:unknown) == "neutral"
      assert TicketStatusColor.status_color(nil) == "neutral"
      assert TicketStatusColor.status_color("something_else") == "neutral"
    end
  end
end
