defmodule WeCraft.Projects.UseCases.CreateProjectUseCase do
  @moduledoc """
  Use case for creating a new project.
  This module handles the logic for creating a new project, including validation and persistence.
  """

  alias WeCraft.Chats
  alias WeCraft.Projects.Infrastructure.Ecto.{ProjectEventsRepositoryEcto, ProjectRepositoryEcto}

  def create_project(%{attrs: attrs}) do
    with {:ok, project} <- ProjectRepositoryEcto.create_project(attrs),
         {:ok, _chat} <-
           Chats.create_project_chat(%{
             attrs: %{is_main: true, project_id: project.id, is_public: true, type: "channel"}
           }),
         {:ok, _event} <-
           ProjectEventsRepositoryEcto.create_event(%{
             event_type: "project_created",
             project_id: project.id
           }) do
      {:ok, project}
    end
  end
end
