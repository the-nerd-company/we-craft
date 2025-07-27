#!/usr/bin/env elixir

# WeCraft Rich Messages Demo
# This script demonstrates the Slack-like rich message formatting system

defmodule RichMessageDemo do
  @moduledoc """
  Demonstration of WeCraft's Slack-like rich message system
  """

  def run do
    IO.puts("=== WeCraft Rich Messages Demo ===\n")

    examples = [
      {
        "Basic mention",
        "Hey <@123|John>, how are you today?"
      },
      {
        "Channel mention with emoji",
        "Check the <#456|general> channel for updates :rocket:"
      },
      {
        "Link with custom text",
        "Visit <https://wecraft.dev|our website> for more info"
      },
      {
        "Auto-detected URL",
        "Also check https://github.com/wecraft for the source code"
      },
      {
        "Special mention",
        "<!here> can everyone please review the latest changes?"
      },
      {
        "Multiple emojis",
        "Great work everyone! :fire: :clap: :tada:"
      },
      {
        "Formatted text",
        "This is *bold*, _italic_, ~strikethrough~ and `code`"
      },
      {
        "Block quote",
        "> \"The best way to predict the future is to create it.\" - Peter Drucker"
      },
      {
        "Code block",
        "```\ndef greet(name)\n  puts \"Hello, \#{name}!\"\nend\n```"
      },
      {
        "Complex message",
        """
        # Project Update :rocket:

        Hey <@123|John> and team!

        > The new rich messaging system is ready for testing

        Key features:
        - User mentions <@456|Alice>
        - Channel links <#789|announcements>
        - Auto-detected URLs: https://wecraft.dev
        - Emojis :fire: :thumbsup:

        ```elixir
        # Example usage
        WeCraft.Chats.send_message(%{
          content: "Hello <@user_id|User>!",
          chat_id: 1
        })
        ```

        <!here> What do you think? Let's discuss in <#general|general>!
        """
      }
    ]

    Enum.each(examples, fn {title, content} ->
      IO.puts("**#{title}:**")
      IO.puts("Input:  #{inspect(content)}")

      # In a real application, you would call:
      # {blocks, mentions, links} = WeCraft.Chats.RichTextProcessor.process(content)

      IO.puts("Output: [Would be processed into rich blocks, mentions, and links]")
      IO.puts("")
    end)

    IO.puts("=== Message Structure Examples ===\n")

    show_message_structure()

    IO.puts("=== Frontend Integration ===\n")

    show_frontend_examples()
  end

  defp show_message_structure do
    IO.puts("""
    Rich messages are stored with this structure:

    ```json
    {
      "content": "Original message text",
      "blocks": [
        {
          "type": "section",
          "text": {
            "type": "mrkdwn",
            "text": "Hey <@123|John>, check this out!"
          },
          "elements": [
            {
              "type": "user",
              "user_id": "123",
              "display_name": "John"
            }
          ]
        }
      ],
      "mentions": [
        {
          "type": "user",
          "user_id": "123",
          "display_name": "John"
        }
      ],
      "links": [],
      "reactions": [],
      "metadata": {}
    }
    ```
    """)
  end

  defp show_frontend_examples do
    IO.puts("""
    LiveView Component Usage:

    ```elixir
    # In your template
    <.live_component
      module={WeCraftWeb.Components.RichMessage}
      id={"rich-message-\#{message.id}"}
      message={message}
    />
    ```

    Rich Text Input:

    ```html
    <input
      type="text"
      phx-hook="RichTextInput"
      placeholder="Type @ for mentions, : for emojis..."
    />
    ```

    JavaScript Integration:

    ```javascript
    // Automatic mention popup when typing @username
    // Automatic emoji popup when typing :emoji_name
    // Auto-link detection for URLs
    // Rich formatting preview
    ```
    """)
  end
end

# Run the demo
RichMessageDemo.run()
