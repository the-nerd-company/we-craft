defmodule WeCraft.Milestones.UseCases.GetMilestoneUseCase do
  @moduledoc """
  Use case for getting a single milestone with proper authorization.
  """

  alias WeCraft.Milestones.Infrastructure.Ecto.MilestoneRepositoryEcto
  alias WeCraft.Milestones.MilestonePermissions

  def get_milestone(%{milestone_id: milestone_id, scope: scope}) do
    case MilestoneRepositoryEcto.get_milestone(milestone_id) do
      {:error, :not_found} ->
        {:ok, nil}

      {:ok, milestone} ->
        if MilestonePermissions.can_view_milestone?(milestone, scope) do
          {:ok, milestone}
        else
          {:error, :unauthorized}
        end
    end
  end

  # For backward compatibility with calls that don't include scope
  def get_milestone(%{milestone_id: milestone_id}) do
    case MilestoneRepositoryEcto.get_milestone(milestone_id) do
      {:error, :not_found} -> {:ok, nil}
      {:ok, milestone} -> {:ok, milestone}
    end
  end
end
