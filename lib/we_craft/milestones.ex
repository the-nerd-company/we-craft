defmodule WeCraft.Milestones do
  @moduledoc """
  The Milestones context for the WeCraft application.
  This module serves as the entry point for all operations related to milestones, including creation, updates, and retrieval.
  It encapsulates the business logic and interacts with the underlying repositories.
  """

  alias WeCraft.Milestones.UseCases.{
    CreateMilestoneUseCase,
    CreateTaskUseCase,
    DeleteMilestoneUseCase,
    DeleteTaskUseCase,
    GetMilestoneUseCase,
    GetTaskUseCase,
    ListMilestoneTasksUseCase,
    ListProjectMilestonesUseCase,
    UpdateMilestoneUseCase,
    UpdateTaskUseCase
  }

  defdelegate create_milestone(attrs), to: CreateMilestoneUseCase
  defdelegate get_milestone(params), to: GetMilestoneUseCase
  defdelegate list_project_milestones(params), to: ListProjectMilestonesUseCase
  defdelegate update_milestone(params), to: UpdateMilestoneUseCase
  defdelegate delete_milestone(params), to: DeleteMilestoneUseCase
  defdelegate create_task(attrs), to: CreateTaskUseCase
  defdelegate get_task(params), to: GetTaskUseCase
  defdelegate list_milestone_tasks(params), to: ListMilestoneTasksUseCase
  defdelegate update_task(params), to: UpdateTaskUseCase
  defdelegate delete_task(params), to: DeleteTaskUseCase
end
