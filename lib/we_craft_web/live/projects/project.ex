defmodule WeCraftWeb.Projects.Project do
  @moduledoc """
  LiveView for displaying a specific project.
  """
  use WeCraftWeb, :live_view

  alias WeCraft.{Chats, Milestones, Pages, Projects}
  alias WeCraftWeb.Projects.ChatComponent

  alias WeCraftWeb.Projects.Components.{
    ContactFormComponent,
    NewChannelModalComponent
  }

  alias WeCraftWeb.Components.LeftMenu

  def mount(%{"project_id" => project_id}, _session, socket) do
    project_id = String.to_integer(project_id)
    scope = socket.assigns.current_scope

    case Projects.get_project(%{project_id: project_id, scope: scope}) do
      {:ok, nil} ->
        {:ok, push_navigate(socket, to: ~p"/")}

      {:ok, project} ->
        {:ok, chats} = Chats.list_project_chats(%{project_id: project.id})
        {:ok, events} = Projects.list_project_events(%{project_id: project.id})
        {:ok, pages} = Pages.list_project_pages(%{project: project, scope: scope})

        # Check if current user is following this project (only for authenticated users)
        {following, user} =
          if scope && scope.user do
            {:ok, following} =
              Projects.check_following_status(%{
                user_id: scope.user.id,
                project_id: project.id
              })

            {following, scope.user}
          else
            {false, nil}
          end

        # Get follower count for the project
        {:ok, followers_count} =
          Projects.get_project_followers_count(%{project_id: project.id})

        current_chat =
          case chats do
            [first_chat | _] -> first_chat
            [] -> nil
          end

        # Get active milestones for the left menu
        active_milestones = get_active_milestones(project.id, scope)

        {:ok,
         socket
         |> assign(:project, project)
         |> assign(:chats, chats)
         |> assign(:current_chat, current_chat)
         |> assign(:events, events)
         |> assign(:active_milestones, active_milestones)
         |> assign(:current_user, user)
         |> assign(:following, following)
         |> assign(:pages, pages)
         |> assign(:followers_count, followers_count)
         |> assign(:contact_modal_open, false)
         |> assign(:new_channel_modal_open, false)
         |> assign(:page_title, project.title)}
    end
  end

  def handle_event("toggle-sidebar", _params, socket) do
    {:noreply, assign(socket, :sidebar_open, !socket.assigns[:sidebar_open])}
  end

  def handle_event("close-contact-modal", _, socket) do
    {:noreply, assign(socket, :contact_modal_open, false)}
  end

  def handle_event("open-contact-modal", _, socket) do
    {:noreply, assign(socket, :contact_modal_open, true)}
  end

  def handle_event("toggle-follow", _, socket) do
    # Only authenticated users can follow/unfollow
    if socket.assigns.current_user do
      current_following = socket.assigns.following
      user_id = socket.assigns.current_user.id
      project_id = socket.assigns.project.id

      result =
        if current_following do
          Projects.unfollow_project(%{user_id: user_id, project_id: project_id})
        else
          Projects.follow_project(%{user_id: user_id, project_id: project_id})
        end

      case result do
        {:ok, _} ->
          # Update the follower count after successful follow/unfollow
          {:ok, new_followers_count} =
            Projects.get_project_followers_count(%{project_id: project_id})

          {:noreply,
           socket
           |> assign(:following, !current_following)
           |> assign(:followers_count, new_followers_count)}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Could not update following status")}
      end
    else
      {:noreply, put_flash(socket, :error, "You must log in to follow projects")}
    end
  end

  def handle_event("join-team", _, socket) do
    if socket.assigns.current_user do
      {:noreply, put_flash(socket, :info, "Request to join team sent!")}
    else
      {:noreply, put_flash(socket, :error, "You must log in to join teams")}
    end
  end

  def handle_info({:chat_selected, chat_id}, socket) do
    case Enum.find(socket.assigns.chats, &(&1.id == chat_id)) do
      nil ->
        {:noreply, socket}

      chat ->
        {:noreply, assign(socket, :current_chat, chat)}
    end
  end

  def handle_info({:section_changed, section}, socket) do
    {:noreply, assign(socket, :current_section, section)}
  end

  def handle_info({:show_flash, kind, message}, socket) do
    {:noreply, put_flash(socket, kind, message)}
  end

  def handle_info({:contact_form_submitted, message}, socket) do
    # Only authenticated users can send messages
    if socket.assigns.current_user do
      {:ok, chat} =
        Chats.create_dm_chat(%{
          attrs: %{
            sender_id: socket.assigns.current_user.id,
            recipient_id: socket.assigns.project.owner.id
          },
          chat: nil,
          scope: socket.assigns.current_scope
        })

      {:ok, _message} =
        Chats.send_message(%{
          content: message,
          sender_id: socket.assigns.current_user.id,
          chat_id: chat.id
        })

      # In a real app, this would send a message to the project owner
      # The message parameter contains the actual message content
      socket =
        socket
        |> put_flash(:info, "Message sent successfully!")
        |> assign(:contact_modal_open, false)

      {:noreply, socket}
    else
      {:noreply, put_flash(socket, :error, "You must log in to send messages")}
    end
  end

  def handle_info(:close_contact_modal, socket) do
    {:noreply, assign(socket, :contact_modal_open, false)}
  end

  def handle_info({:new_message, message}, socket) do
    send_update(WeCraftWeb.Projects.ChatComponent,
      id: "project-chat",
      new_message: message
    )

    {:noreply, socket}
  end

  def handle_info({:message_updated, message}, socket) do
    send_update(WeCraftWeb.Projects.ChatComponent,
      id: "project-chat",
      updated_message: message
    )

    {:noreply, socket}
  end

  def handle_info(:open_contact_modal, socket) do
    {:noreply, assign(socket, :contact_modal_open, true)}
  end

  def handle_info(:toggle_follow, socket) do
    # Only authenticated users can follow/unfollow
    if socket.assigns.current_user do
      current_following = socket.assigns.following
      user_id = socket.assigns.current_user.id
      project_id = socket.assigns.project.id

      result =
        if current_following do
          Projects.unfollow_project(%{user_id: user_id, project_id: project_id})
        else
          Projects.follow_project(%{user_id: user_id, project_id: project_id})
        end

      case result do
        {:ok, _} ->
          # Update the follower count after successful follow/unfollow
          {:ok, new_followers_count} =
            Projects.get_project_followers_count(%{project_id: project_id})

          {:noreply,
           socket
           |> assign(:following, !current_following)
           |> assign(:followers_count, new_followers_count)}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Could not update following status")}
      end
    else
      {:noreply, put_flash(socket, :error, "You must log in to follow projects")}
    end
  end

  def handle_info(:join_team, socket) do
    if socket.assigns.current_user do
      {:noreply, put_flash(socket, :info, "Request to join team sent!")}
    else
      {:noreply, put_flash(socket, :error, "You must log in to join teams")}
    end
  end

  def handle_info(:open_new_channel_modal, socket) do
    {:noreply, assign(socket, :new_channel_modal_open, true)}
  end

  def handle_info(:close_new_channel_modal, socket) do
    {:noreply, assign(socket, :new_channel_modal_open, false)}
  end

  def handle_info({:channel_created, chat}, socket) do
    # Ensure the new chat has messages initialized as an empty list
    chat_with_messages = %{chat | messages: []}
    updated_chats = [chat_with_messages | socket.assigns.chats]

    socket =
      socket
      |> assign(:chats, updated_chats)
      |> assign(:current_chat, chat_with_messages)
      |> put_flash(:info, "Channel '#{chat.name}' created successfully!")

    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="project-page min-h-screen bg-gradient-to-br from-base-100 to-base-200">
      <div class="flex h-screen">
        <!-- Left Menu -->
        <.live_component
          module={LeftMenu}
          pages={@pages}
          id="left-menu"
          project={@project}
          current_scope={@current_scope}
          current_section={:chat}
          chats={@chats}
          current_chat={@current_chat}
          active_milestones={@active_milestones}
        />
        
    <!-- Main Content Area -->
                <!-- Main Content Area -->
        <div class="flex-1 flex flex-col">
          <!-- Chat Area -->
          <%= if @current_chat do %>
            <.live_component
              module={ChatComponent}
              id="project-chat"
              chat={@current_chat}
              current_user={@current_user}
            />
          <% else %>
            <div class="flex-1 flex items-center justify-center">
              <div class="text-center text-base-content/70">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-16 w-16 mx-auto mb-4 opacity-50"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="1"
                    d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"
                  />
                </svg>
                <p class="text-lg font-medium">No chat selected</p>
                <p class="text-sm">Select a chat from the sidebar to start messaging.</p>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <%= if @contact_modal_open do %>
        <.live_component module={ContactFormComponent} id="contact-form" owner={@project.owner} />
      <% end %>

      <%= if @new_channel_modal_open do %>
        <.live_component
          module={NewChannelModalComponent}
          id="new-channel-modal"
          project={@project}
          show={@new_channel_modal_open}
        />
      <% end %>
    </div>
    """
  end

  defp get_active_milestones(project_id, scope) do
    case Milestones.list_project_milestones(%{project_id: project_id, scope: scope}) do
      {:ok, milestones} ->
        milestones
        |> Enum.filter(&(&1.status == :active))

      {:error, _} ->
        []
    end
  end
end
