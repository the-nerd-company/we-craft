# WeCraft Rich Messages System

This document demonstrates the Slack-like rich message formatting system implemented for WeCraft.

## Overview

The system supports the following rich content types:
- **User Mentions**: `<@user_id|display_name>` or `<@user_id>`
- **Channel Links**: `<#channel_id|display_name>` or `<#channel_id>`
- **URLs**: `<https://example.com|Link Text>` or auto-detected URLs
- **Email Links**: `<mailto:user@example.com|Email User>`
- **Special Mentions**: `<!here>`, `<!channel>`, `<!everyone>`
- **Emojis**: `:smile:`, `:heart:`, `:rocket:`
- **Dates**: `<!date^1640995200^{date} at {time}|Dec 31, 2021 at 12:00 PM>`
- **Formatting**: `*bold*`, `_italic_`, `~strikethrough~`, `\`code\``
- **Block Quotes**: `> This is a quote`
- **Code Blocks**: `\`\`\`This is code\`\`\``
- **Headers**: `# Header 1`, `## Header 2`, etc.

## Example Messages

### Basic Text with Mentions
```
Input:  "Hey <@123|John>, can you check the <#456|general> channel?"
Output: "Hey @John, can you check the #general channel?"
```

### Message with Links and Emojis
```
Input:  "Check out <https://wecraft.dev|our website> :rocket: :fire:"
Output: "Check out [our website](https://wecraft.dev) 🚀 🔥"
```

### Formatted Text
```
Input:  "This is *bold*, _italic_, and ~strikethrough~ text with `code`"
Output: "This is **bold**, *italic*, and ~~strikethrough~~ text with `code`"
```

### Block Quote
```
Input:  "> This is an important quote from someone"
Output: > This is an important quote from someone
```

### Code Block
```
Input:  "```\nconst greeting = 'Hello World';\nconsole.log(greeting);\n```"
Output: 
```
const greeting = 'Hello World';
console.log(greeting);
```
```

### Special Mentions
```
Input:  "<!here> can everyone please review this?"
Output: "@here can everyone please review this?"
```

## Database Structure

The enhanced message table includes:

```sql
-- Rich content stored as JSON blocks (similar to Slack's structure)
blocks JSONB DEFAULT '[]',

-- Parsed mentions for quick lookups and notifications
mentions JSONB DEFAULT '[]',

-- Extracted links for preview/security scanning
links JSONB DEFAULT '[]',

-- Message type classification
message_type VARCHAR DEFAULT 'text',

-- Raw content for editing
raw_content TEXT,

-- Pre-processed HTML for display
html_content TEXT,

-- Thread support
thread_ts VARCHAR,
parent_message_id INTEGER REFERENCES messages(id),

-- Reaction support
reactions JSONB DEFAULT '[]',

-- Additional metadata
metadata JSONB DEFAULT '{}'
```

## Block Structure Examples

### Simple Text Message
```json
{
  "blocks": [
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "Hello world!"
      },
      "elements": []
    }
  ]
}
```

### Message with User Mention
```json
{
  "blocks": [
    {
      "type": "section",
      "text": {
        "type": "mrkdwn", 
        "text": "Hey <@123|John>, how are you?"
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
  ]
}
```

### Message with Link
```json
{
  "blocks": [
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "Check out <https://wecraft.dev|WeCraft>"
      },
      "elements": [
        {
          "type": "link",
          "url": "https://wecraft.dev",
          "display_text": "WeCraft"
        }
      ]
    }
  ],
  "links": [
    {
      "type": "link", 
      "url": "https://wecraft.dev",
      "display_text": "WeCraft"
    }
  ]
}
```

### Message with Header and Code
```json
{
  "blocks": [
    {
      "type": "header",
      "level": 2,
      "text": {
        "type": "plain_text",
        "text": "Code Example"
      }
    },
    {
      "type": "code",
      "text": "def hello_world\n  puts 'Hello, World!'\nend"
    }
  ]
}
```

## Frontend Integration

### LiveView Component Usage
```elixir
<.live_component 
  module={WeCraftWeb.Components.RichMessage}
  id={"rich-message-#{message.id}"}
  message={message}
/>
```

### JavaScript Rich Input
```html
<input 
  type="text" 
  phx-hook="RichTextInput"
  placeholder="Type your message... Use @username for mentions"
/>
```

## API Usage Examples

### Creating a Rich Message
```elixir
# Simple message with mention
WeCraft.Chats.send_message(%{
  content: "Hey <@#{user.id}|#{user.name}>, welcome to the project!",
  sender_id: current_user.id,
  chat_id: chat.id
})

# The processor automatically extracts:
# - blocks: Structured representation
# - mentions: [%{"type" => "user", "user_id" => "123", "display_name" => "John"}]
# - links: []
```

### Querying Messages with Mentions
```elixir
# Find all messages mentioning a specific user
from(m in Message, 
  where: fragment("? @> ?", m.mentions, ^[%{"user_id" => user.id}])
)

# Find messages with links
from(m in Message, 
  where: fragment("jsonb_array_length(?) > 0", m.links)
)
```

## Styling

The system includes Tailwind CSS classes for rich formatting:

```css
/* Mentions */
.mention-user { @apply bg-primary/20 text-primary px-1 rounded hover:bg-primary/30 cursor-pointer; }
.mention-channel { @apply bg-info/20 text-info px-1 rounded hover:bg-info/30 cursor-pointer; }
.mention-special { @apply px-1 rounded font-medium; }

/* Content blocks */
.message-header { @apply font-bold mb-2; }
.message-code { @apply bg-base-200 p-3 rounded-md overflow-x-auto; }
.message-quote { @apply border-l-4 border-primary pl-4 italic text-base-content/80; }

/* Links */
.link { @apply text-primary hover:text-accent underline; }

/* Emojis */
.emoji { @apply text-lg; }
```

## Migration Guide

To upgrade existing messages to support rich content:

1. Run the migration:
```bash
mix ecto.migrate
```

2. Backfill existing messages (optional):
```elixir
# Process existing messages to extract rich content
WeCraft.Chats.Message
|> Repo.all()
|> Enum.each(fn message ->
  changeset = WeCraft.Chats.Message.changeset(message, %{})
  Repo.update!(changeset)
end)
```

## Security Considerations

- All URLs are validated and escaped
- User mentions are verified against actual users
- HTML output is properly escaped to prevent XSS
- Link previews should include security scanning
- File uploads should be validated and scanned

## Performance Optimizations

- JSON fields use GIN indexes for fast querying
- Mentions are pre-extracted for notification systems
- HTML content is pre-processed and cached
- Block rendering is optimized for LiveView updates
