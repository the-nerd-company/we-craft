defmodule WeCraft.Milestones.MilestoneUpdateStatus do
  @moduledoc """
  Module for handling updates to milestone status.
  """

  def generate_events(milestone, attrs, scope) do
    events = []

    events =
      if milestone_completed_now?(%{milestone: milestone, attrs: attrs}) do
        events ++
          [
            %{
              project_id: milestone.project_id,
              event_type: "milestone_completed",
              metadata: %{
                "milestone_id" => milestone.id,
                "milestone_title" => milestone.title,
                "user_id" => scope.user.id
              }
            }
          ]
      else
        events
      end

    events =
      if milestone_active_now?(%{milestone: milestone, attrs: attrs}) do
        events ++
          [
            %{
              project_id: milestone.project_id,
              event_type: "milestone_active",
              metadata: %{
                "milestone_id" => milestone.id,
                "milestone_title" => milestone.title,
                "user_id" => scope.user.id
              }
            }
          ]
      else
        events
      end

    events
  end

  defp milestone_active_now?(%{milestone: %{status: :active}, attrs: nil}), do: true

  defp milestone_active_now?(%{milestone: %{status: :active}}), do: false

  defp milestone_active_now?(%{attrs: attrs, milestone: milestone}) do
    new_status = get_status_from_attrs(attrs)
    current_status = milestone.status

    # Only create event if milestone is being changed to active status
    current_status != :active and to_string(new_status) == "active"
  end

  defp milestone_completed_now?(%{milestone: %{status: :completed}, attrs: nil}), do: true

  defp milestone_completed_now?(%{milestone: %{status: :completed}}), do: false

  defp milestone_completed_now?(%{attrs: attrs, milestone: milestone}) do
    new_status = get_status_from_attrs(attrs)
    current_status = milestone.status

    # Only create event if milestone is being changed to completed status
    current_status != :completed and to_string(new_status) == "completed"
  end

  defp get_status_from_attrs(%{status: status}), do: status
  defp get_status_from_attrs(%{"status" => status}), do: status
  defp get_status_from_attrs(_), do: nil
end
