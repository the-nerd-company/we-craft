defmodule WeCraftWeb.Components.RichMessage do
  @moduledoc """
  LiveView component for rendering rich text messages with Slack-like formatting.
  """
  use WeCraftWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="rich-message">
      <%= if WeCraft.Chats.Message.has_rich_content?(@message) do %>
        <%= for block <- render_rich_blocks(@message.blocks) do %>
          {block}
        <% end %>
      <% else %>
        <div class="message-section">
          {@message.content}
        </div>
      <% end %>
      
    <!-- Reactions Display -->
      <%= if @message.reactions != [] do %>
        <div class="flex flex-wrap gap-1 mt-2">
          <%= for reaction <- @message.reactions do %>
            <%= if @current_user do %>
              <button
                class="badge badge-sm bg-base-200 hover:bg-base-300 transition-colors cursor-pointer flex items-center gap-1"
                phx-click="toggle_reaction"
                phx-value-message-id={@message.id}
                phx-value-emoji={reaction["emoji"]}
                phx-target={@chat_target}
              >
                <span>{reaction["emoji"]}</span>
                <span class="text-xs">{length(reaction["users"] || [])}</span>
              </button>
            <% else %>
              <div class="badge badge-sm bg-base-200 flex items-center gap-1">
                <span>{reaction["emoji"]}</span>
                <span class="text-xs">{length(reaction["users"] || [])}</span>
              </div>
            <% end %>
          <% end %>
        </div>
      <% end %>
      
    <!-- Add Reaction Button -->
      <%= if @current_user do %>
        <div class="flex items-center gap-2 mt-1">
          <div class="dropdown dropdown-top">
            <div tabindex="0" role="button" class="btn btn-ghost btn-xs hover:bg-base-200">
              <span class="text-sm">😊</span>
            </div>
            <div
              tabindex="0"
              class="dropdown-content z-[1] menu p-2 shadow bg-base-100 rounded-box w-48"
            >
              <div class="grid grid-cols-6 gap-1">
                <%= for emoji <- common_emojis() do %>
                  <button
                    class="btn btn-ghost btn-xs text-lg hover:bg-base-200"
                    phx-click="add_reaction"
                    phx-value-message-id={@message.id}
                    phx-value-emoji={emoji}
                    phx-target={@chat_target}
                  >
                    {emoji}
                  </button>
                <% end %>
              </div>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  defp render_rich_blocks(blocks) when is_list(blocks) do
    Enum.map(blocks, &render_block/1)
  end

  defp render_rich_blocks(_), do: []

  defp render_block(%{"type" => "section", "text" => %{"text" => text}, "elements" => elements}) do
    assigns = %{text: text, elements: elements}

    ~H"""
    <div class="message-section">
      {render_text_with_elements(@text, @elements)}
    </div>
    """
  end

  defp render_block(%{"type" => "header", "level" => level, "text" => %{"text" => text}}) do
    assigns = %{level: level, text: text}

    case level do
      1 -> ~H[<h1 class="message-header text-2xl font-bold mb-2">{@text}</h1>]
      2 -> ~H[<h2 class="message-header text-xl font-bold mb-2">{@text}</h2>]
      3 -> ~H[<h3 class="message-header text-lg font-bold mb-1">{@text}</h3>]
      _ -> ~H[<h4 class="message-header text-base font-bold mb-1">{@text}</h4>]
    end
  end

  defp render_block(%{"type" => "code", "text" => text}) do
    assigns = %{text: text}

    ~H"""
    <pre class="message-code bg-base-200 p-3 rounded-md overflow-x-auto">
      <code class="text-sm"><%= @text %></code>
    </pre>
    """
  end

  defp render_block(%{"type" => "quote", "text" => text}) do
    assigns = %{text: text}

    ~H"""
    <blockquote class="message-quote border-l-4 border-primary pl-4 italic text-base-content/80">
      {@text}
    </blockquote>
    """
  end

  defp render_block(_block), do: []

  defp render_text_with_elements(text, elements) do
    Enum.reduce(elements, text, &apply_element_rendering/2)
    |> raw()
  end

  defp apply_element_rendering(element, acc_text) do
    case element["type"] do
      "user" -> apply_user_mention(element, acc_text)
      "channel" -> apply_channel_mention(element, acc_text)
      "link" -> apply_link(element, acc_text)
      "special_mention" -> apply_special_mention(element, acc_text)
      "emoji" -> apply_emoji(element, acc_text)
      "date" -> apply_date(element, acc_text)
      _ -> acc_text
    end
  end

  defp apply_user_mention(%{"user_id" => user_id, "display_name" => display_name}, acc_text) do
    String.replace(
      acc_text,
      "<@#{user_id}>",
      ~s(<span class="mention mention-user bg-primary/20 text-primary px-1 rounded hover:bg-primary/30 cursor-pointer" data-user-id="#{user_id}">@#{display_name}</span>)
    )
  end

  defp apply_channel_mention(
         %{"channel_id" => channel_id, "display_name" => display_name},
         acc_text
       ) do
    String.replace(
      acc_text,
      "<##{channel_id}>",
      ~s(<span class="mention mention-channel bg-info/20 text-info px-1 rounded hover:bg-info/30 cursor-pointer" data-channel-id="#{channel_id}">##{display_name}</span>)
    )
  end

  defp apply_link(%{"url" => url, "display_text" => display_text}, acc_text) do
    link_pattern = if display_text == url, do: url, else: "<#{url}|#{display_text}>"

    String.replace(
      acc_text,
      link_pattern,
      ~s(<a href="#{url}" target="_blank" rel="noopener noreferrer" class="link link-primary hover:link-accent">#{display_text}</a>)
    )
  end

  defp apply_special_mention(%{"mention" => mention}, acc_text) do
    mention_class = get_special_mention_class(mention)

    String.replace(
      acc_text,
      "<!#{mention}>",
      ~s(<span class="mention mention-special #{mention_class} px-1 rounded font-medium">@#{mention}</span>)
    )
  end

  defp apply_emoji(%{"name" => name}, acc_text) do
    String.replace(
      acc_text,
      ":#{name}:",
      ~s(<span class="emoji text-lg" title=":#{name}:" data-emoji="#{name}">#{get_emoji_unicode(name)}</span>)
    )
  end

  defp apply_date(
         %{"timestamp" => timestamp, "format" => format, "fallback" => fallback},
         acc_text
       ) do
    formatted_date = format_date(timestamp, format, fallback)
    String.replace(acc_text, "<!date^#{timestamp}^#{format}|#{fallback}>", formatted_date)
  end

  defp get_special_mention_class(mention) do
    case mention do
      "here" -> "bg-warning/20 text-warning"
      "channel" -> "bg-error/20 text-error"
      "everyone" -> "bg-error/20 text-error"
      _ -> "bg-accent/20 text-accent"
    end
  end

  # Basic emoji mapping - in a real app, you'd want a comprehensive emoji library
  defp get_emoji_unicode(name) do
    emoji_map = %{
      "smile" => "😄",
      "heart" => "❤️",
      "thumbsup" => "👍",
      "thumbsdown" => "👎",
      "fire" => "🔥",
      "rocket" => "🚀",
      "wave" => "👋",
      "eyes" => "👀",
      "clap" => "👏",
      "tada" => "🎉"
    }

    Map.get(emoji_map, name, ":#{name}:")
  end

  defp format_date(timestamp, _format, fallback) do
    case DateTime.from_unix(timestamp) do
      {:ok, datetime} ->
        relative_time = format_relative_time(datetime)

        ~s(<time class="text-base-content/70 hover:text-base-content cursor-help" title="#{DateTime.to_string(datetime)}">#{relative_time}</time>)

      _ ->
        ~s(<time class="text-base-content/70">#{fallback}</time>)
    end
  end

  defp format_relative_time(datetime) do
    now = DateTime.utc_now()
    diff = DateTime.diff(now, datetime, :second)

    cond do
      diff < 60 -> "just now"
      diff < 3600 -> "#{div(diff, 60)}m ago"
      diff < 86_400 -> "#{div(diff, 3600)}h ago"
      diff < 604_800 -> "#{div(diff, 86_400)}d ago"
      true -> Calendar.strftime(datetime, "%b %d")
    end
  end

  # Common emojis for quick access
  defp common_emojis do
    [
      "👍",
      "👎",
      "❤️",
      "😂",
      "😢",
      "😮",
      "😡",
      "👏",
      "🙌",
      "🔥",
      "💯",
      "✅",
      "❌",
      "⭐",
      "🚀",
      "💡",
      "🎉",
      "👀"
    ]
  end
end
