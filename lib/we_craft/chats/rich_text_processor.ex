defmodule WeCraft.Chats.RichTextProcessor do
  @moduledoc """
  Processes rich text content similar to Slack's formatting system.
  Handles mentions, links, emojis, and block formatting.
  """

  alias WeCraft.Accounts

  @doc """
  Process raw content and return blocks, mentions, and links.
  """
  def process(content) when is_binary(content) do
    blocks = parse_to_blocks(content)
    mentions = extract_mentions(content)
    links = extract_links(content)

    {blocks, mentions, links}
  end

  def process(_), do: {[], [], []}

  @doc """
  Parse content into Slack-like block structure
  """
  def parse_to_blocks(content) do
    content
    |> String.split("\n")
    |> process_lines_with_state([], nil)
    |> Enum.reverse()
  end

  defp process_lines_with_state([], acc, _state), do: acc

  defp process_lines_with_state([line | rest], acc, _state) do
    if String.starts_with?(line, "```") do
      # Start of code block - collect all lines until closing ```
      {code_lines, remaining_lines} = collect_code_block(rest, [])
      code_text = Enum.join(code_lines, "\n")
      code_block = create_code_block(code_text)
      process_lines_with_state(remaining_lines, [code_block | acc], nil)
    else
      # Regular line processing
      block = process_single_line(line)

      if block do
        process_lines_with_state(rest, [block | acc], nil)
      else
        process_lines_with_state(rest, acc, nil)
      end
    end
  end

  defp collect_code_block([], code_lines), do: {Enum.reverse(code_lines), []}

  defp collect_code_block([line | rest], code_lines) do
    if String.starts_with?(line, "```") do
      # End of code block
      {Enum.reverse(code_lines), rest}
    else
      collect_code_block(rest, [line | code_lines])
    end
  end

  defp process_single_line(""), do: nil

  defp process_single_line(line) do
    cond do
      String.starts_with?(line, "> ") ->
        # Block quote
        create_quote_block(line)

      String.match?(line, ~r/^\#{1,6}\s/) ->
        # Header
        create_header_block(line)

      true ->
        # Regular section with rich text
        create_section_block(line)
    end
  end

  defp create_section_block(text) do
    %{
      "type" => "section",
      "text" => %{
        "type" => "mrkdwn",
        "text" => text
      },
      "elements" => parse_inline_elements(text)
    }
  end

  defp create_code_block(text) do
    %{
      "type" => "code",
      "text" => text
    }
  end

  defp create_quote_block(text) do
    %{
      "type" => "quote",
      "text" => String.trim_leading(text, "> ")
    }
  end

  defp create_header_block(text) do
    level = String.length(Regex.run(~r/^#+/, text) |> hd())
    header_text = String.trim_leading(text, String.duplicate("#", level) <> " ")

    %{
      "type" => "header",
      "level" => level,
      "text" => %{
        "type" => "plain_text",
        "text" => header_text
      }
    }
  end

  @doc """
  Parse inline elements like mentions, links, emojis
  """
  def parse_inline_elements(text) do
    elements = []

    elements = elements ++ extract_user_mentions(text)
    elements = elements ++ extract_channel_mentions(text)
    elements = elements ++ extract_inline_links(text)
    elements = elements ++ extract_special_mentions(text)
    elements = elements ++ extract_emojis(text)
    elements = elements ++ extract_dates(text)

    elements
  end

  defp extract_user_mentions(text) do
    ~r/<@(\w+)(?:\|([^>]+))?>/
    |> Regex.scan(text, capture: :all_but_first)
    |> Enum.map(fn
      [user_id] ->
        %{
          "type" => "user",
          "user_id" => user_id,
          "display_name" => get_user_display_name(user_id)
        }

      [user_id, display_name] ->
        %{
          "type" => "user",
          "user_id" => user_id,
          "display_name" => display_name
        }
    end)
  end

  defp extract_channel_mentions(text) do
    ~r/<#(\w+)(?:\|([^>]+))?>/
    |> Regex.scan(text, capture: :all_but_first)
    |> Enum.map(fn
      [channel_id] ->
        %{
          "type" => "channel",
          "channel_id" => channel_id,
          "display_name" => get_channel_display_name(channel_id)
        }

      [channel_id, display_name] ->
        %{
          "type" => "channel",
          "channel_id" => channel_id,
          "display_name" => display_name
        }
    end)
  end

  defp extract_inline_links(text) do
    ~r/<(https?:\/\/[^|>]+)(?:\|([^>]+))?>/
    |> Regex.scan(text, capture: :all_but_first)
    |> Enum.map(fn
      [url] ->
        %{
          "type" => "link",
          "url" => url,
          "display_text" => url
        }

      [url, display_text] ->
        %{
          "type" => "link",
          "url" => url,
          "display_text" => display_text
        }
    end)
  end

  defp extract_special_mentions(text) do
    ~r/<!([^>]+)>/
    |> Regex.scan(text, capture: :all_but_first)
    |> Enum.map(fn [mention] ->
      %{
        "type" => "special_mention",
        "mention" => mention
      }
    end)
  end

  defp extract_emojis(text) do
    ~r/:([a-zA-Z0-9_+-]+):/
    |> Regex.scan(text, capture: :all_but_first)
    |> Enum.map(fn [emoji_name] ->
      %{
        "type" => "emoji",
        "name" => emoji_name
      }
    end)
  end

  defp extract_dates(text) do
    ~r/<!date\^(\d+)\^([^|>]+)(?:\|([^>]+))?>/
    |> Regex.scan(text, capture: :all_but_first)
    |> Enum.map(fn
      [timestamp, format] ->
        %{
          "type" => "date",
          "timestamp" => String.to_integer(timestamp),
          "format" => format,
          "fallback" => format_timestamp_fallback(timestamp)
        }

      [timestamp, format, fallback] ->
        %{
          "type" => "date",
          "timestamp" => String.to_integer(timestamp),
          "format" => format,
          "fallback" => fallback
        }
    end)
  end

  @doc """
  Extract all mentions from content for indexing
  """
  def extract_mentions(content) do
    user_mentions = extract_user_mentions(content)
    channel_mentions = extract_channel_mentions(content)
    special_mentions = extract_special_mentions(content)

    user_mentions ++ channel_mentions ++ special_mentions
  end

  @doc """
  Extract all links from content for indexing
  """
  def extract_links(content) do
    # Extract explicit links
    explicit_links = extract_inline_links(content)

    # Extract email links
    email_links =
      ~r/<mailto:([^|>]+)(?:\|([^>]+))?>/
      |> Regex.scan(content, capture: :all_but_first)
      |> Enum.map(fn
        [email] ->
          %{
            "type" => "email",
            "email" => email,
            "display_text" => email
          }

        [email, display_text] ->
          %{
            "type" => "email",
            "email" => email,
            "display_text" => display_text
          }
      end)

    # Extract auto-detected URLs (not wrapped in <> and not already in explicit links)
    # First, remove all explicit link patterns to avoid double-matching
    content_without_explicit_links =
      content
      |> String.replace(~r/<https?:\/\/[^|>]+(?:\|[^>]+)?>/, "")
      |> String.replace(~r/<mailto:[^|>]+(?:\|[^>]+)?>/, "")

    auto_urls =
      ~r/https?:\/\/[^\s<>]+/
      |> Regex.scan(content_without_explicit_links)
      |> Enum.map(fn [url] ->
        %{
          "type" => "auto_link",
          "url" => url,
          "display_text" => url
        }
      end)

    explicit_links ++ email_links ++ auto_urls
  end

  @doc """
  Convert rich blocks back to display text (for rendering)
  """
  def blocks_to_html(blocks) when is_list(blocks) do
    blocks
    |> Enum.map_join("", &block_to_html/1)
  end

  def blocks_to_html(_), do: ""

  defp block_to_html(%{"type" => "section", "text" => %{"text" => text}, "elements" => elements}) do
    processed_text = apply_inline_elements(text, elements)
    "<div class=\"message-section\">#{processed_text}</div>"
  end

  defp block_to_html(%{"type" => "header", "level" => level, "text" => %{"text" => text}}) do
    "<h#{level} class=\"message-header\">#{html_escape(text)}</h#{level}>"
  end

  defp block_to_html(%{"type" => "code", "text" => text}) do
    "<pre class=\"message-code\"><code>#{html_escape(text)}</code></pre>"
  end

  defp block_to_html(%{"type" => "quote", "text" => text}) do
    "<blockquote class=\"message-quote\">#{html_escape(text)}</blockquote>"
  end

  defp block_to_html(_), do: ""

  defp apply_inline_elements(text, elements) do
    Enum.reduce(elements, text, &apply_element_to_text/2)
  end

  defp apply_element_to_text(element, acc_text) do
    case element do
      %{"type" => "user", "user_id" => user_id, "display_name" => display_name} ->
        String.replace(
          acc_text,
          "<@#{user_id}>",
          "<span class=\"mention mention-user\" data-user-id=\"#{user_id}\">@#{display_name}</span>"
        )

      %{"type" => "channel", "channel_id" => channel_id, "display_name" => display_name} ->
        String.replace(
          acc_text,
          "<##{channel_id}>",
          "<span class=\"mention mention-channel\" data-channel-id=\"#{channel_id}\">##{display_name}</span>"
        )

      %{"type" => "link", "url" => url, "display_text" => display_text} ->
        link_pattern = if display_text == url, do: url, else: "<#{url}|#{display_text}>"

        String.replace(
          acc_text,
          link_pattern,
          "<a href=\"#{url}\" target=\"_blank\" rel=\"noopener noreferrer\">#{display_text}</a>"
        )

      %{"type" => "special_mention", "mention" => mention} ->
        String.replace(
          acc_text,
          "<!#{mention}>",
          "<span class=\"mention mention-special\">@#{mention}</span>"
        )

      %{"type" => "emoji", "name" => name} ->
        String.replace(
          acc_text,
          ":#{name}:",
          "<span class=\"emoji\" data-emoji=\"#{name}\">:#{name}:</span>"
        )

      _ ->
        acc_text
    end
  end

  # Helper functions
  defp get_user_display_name(user_id) do
    case Accounts.get_user!(user_id) do
      %{name: name} -> name
      _ -> "Unknown User"
    end
  rescue
    _ -> "Unknown User"
  end

  defp get_channel_display_name(_channel_id) do
    # In WeCraft context, this might be project names or chat names
    "general"
  end

  defp format_timestamp_fallback(timestamp_str) do
    case Integer.parse(timestamp_str) do
      {timestamp, _} ->
        timestamp
        |> DateTime.from_unix!()
        |> DateTime.to_string()

      _ ->
        timestamp_str
    end
  end

  defp html_escape(text) do
    text
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
    |> String.replace("'", "&#39;")
  end
end
