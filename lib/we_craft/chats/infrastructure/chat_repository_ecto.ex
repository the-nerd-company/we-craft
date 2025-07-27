defmodule WeCraft.Chats.Infrastructure.ChatRepositoryEcto do
  @moduledoc """
  Ecto implementation of the ProjectRepository.
  """

  alias WeCraft.Chats.Chat
  alias WeCraft.Repo

  import Ecto.Query, warn: false

  def list_chats_by_project(project_id) do
    Repo.all(
      from c in Chat,
        where: c.project_id == ^project_id,
        order_by: [desc: c.is_main, asc: c.inserted_at]
    )
    |> Repo.preload(messages: [:sender])
  end

  def list_dm_chats(user_id) do
    Repo.all(
      from c in Chat,
        where: c.type == "dm",
        join: m in assoc(c, :members),
        where: m.user_id == ^user_id,
        preload: [:messages, members: [:user]]
    )
  end

  def get_dm_chat(%{sender_id: sender_id, recipient_id: recipient_id}) do
    # Use a more robust approach: find chats where both users are members
    # and the total member count is exactly 2
    chat_id =
      Repo.one(
        from c in Chat,
          where: c.type == "dm",
          # Subquery to ensure the chat has both users as members
          where:
            c.id in subquery(
              from c2 in Chat,
                join: m in assoc(c2, :members),
                where: c2.type == "dm",
                where: m.user_id in [^sender_id, ^recipient_id],
                group_by: c2.id,
                having:
                  count(m.id) == 2 and
                    fragment(
                      "array_agg(DISTINCT ?) @> ARRAY[?::bigint, ?::bigint]",
                      m.user_id,
                      ^sender_id,
                      ^recipient_id
                    ),
                select: c2.id
            ),
          # Subquery to ensure the chat has exactly 2 total members
          where:
            c.id in subquery(
              from c3 in Chat,
                join: m2 in assoc(c3, :members),
                group_by: c3.id,
                having: count(m2.id) == 2,
                select: c3.id
            ),
          select: c.id,
          limit: 1
      )

    case chat_id do
      nil ->
        nil

      id ->
        Repo.get(Chat, id)
        |> Repo.preload([:messages, members: [:user]])
    end
  end

  def get_chat!(id) do
    Repo.get!(Chat, id)
    |> Repo.preload(messages: [:sender], members: [:user])
  end

  def create_chat(attrs) do
    %Chat{}
    |> Chat.changeset(attrs)
    |> Repo.insert()
  end
end
