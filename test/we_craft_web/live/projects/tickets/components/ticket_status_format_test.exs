defmodule WeCraftWeb.Projects.Tickets.Components.TicketStatusFormatTest do
  @moduledoc """
  Tests for the TicketStatusFormat module.
  """
  use ExUnit.Case, async: true

  alias WeCraftWeb.Projects.Tickets.Components.TicketStatusFormat

  describe ".format_ticket_status/1" do
    test "formats atom with underscores" do
      assert TicketStatusFormat.format_ticket_status(:in_progress) == "In Progress"
    end

    test "formats atom without underscores" do
      assert TicketStatusFormat.format_ticket_status(:done) == "Done"
    end

    test "formats string input" do
      assert TicketStatusFormat.format_ticket_status("new") == "New"
    end

    test "formats mixed case string" do
      assert TicketStatusFormat.format_ticket_status("in_Review") == "In Review"
    end
  end

  describe ".format_ticket_type/1" do
    test "formats atom with underscores" do
      assert TicketStatusFormat.format_ticket_type(:feature_request) == "Feature Request"
    end

    test "formats atom without underscores" do
      assert TicketStatusFormat.format_ticket_type(:bug) == "Bug"
    end

    test "formats string input" do
      assert TicketStatusFormat.format_ticket_type("support") == "Support"
    end

    test "formats mixed case string" do
      assert TicketStatusFormat.format_ticket_type("user_story") == "User Story"
    end
  end
end
