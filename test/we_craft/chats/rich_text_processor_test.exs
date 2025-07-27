defmodule WeCraft.Chats.RichTextProcessorTest do
  @moduledoc """
  Tests for the RichTextProcessor module that handles Slack-like message formatting.
  """
  use WeCraft.DataCase

  alias WeCraft.Chats.RichTextProcessor

  describe "process/1" do
    test "processes simple text message" do
      content = "Hello world!"
      {blocks, mentions, links} = RichTextProcessor.process(content)

      assert length(blocks) == 1
      assert hd(blocks)["type"] == "section"
      assert hd(blocks)["text"]["text"] == "Hello world!"
      assert mentions == []
      assert links == []
    end

    test "processes user mentions" do
      content = "Hey <@123|John>, how are you?"
      {_blocks, mentions, _links} = RichTextProcessor.process(content)

      assert length(mentions) == 1
      mention = hd(mentions)
      assert mention["type"] == "user"
      assert mention["user_id"] == "123"
      assert mention["display_name"] == "John"
    end

    test "processes channel mentions" do
      content = "Check the <#456|general> channel"
      {_blocks, mentions, _links} = RichTextProcessor.process(content)

      assert length(mentions) == 1
      mention = hd(mentions)
      assert mention["type"] == "channel"
      assert mention["channel_id"] == "456"
      assert mention["display_name"] == "general"
    end

    test "processes links" do
      content = "Visit <https://wecraft.dev|our site>"
      {_blocks, _mentions, links} = RichTextProcessor.process(content)

      assert length(links) == 1
      link = hd(links)
      assert link["type"] == "link"
      assert link["url"] == "https://wecraft.dev"
      assert link["display_text"] == "our site"
    end

    test "processes auto-detected URLs" do
      content = "Visit https://wecraft.dev for more info"
      {_blocks, _mentions, links} = RichTextProcessor.process(content)

      assert length(links) == 1
      link = hd(links)
      assert link["type"] == "auto_link"
      assert link["url"] == "https://wecraft.dev"
    end

    test "processes emojis" do
      content = "Great work :rocket: :fire:"
      {blocks, _mentions, _links} = RichTextProcessor.process(content)

      elements = hd(blocks)["elements"]
      emoji_elements = Enum.filter(elements, &(&1["type"] == "emoji"))

      assert length(emoji_elements) == 2
      assert Enum.any?(emoji_elements, &(&1["name"] == "rocket"))
      assert Enum.any?(emoji_elements, &(&1["name"] == "fire"))
    end

    test "processes special mentions" do
      content = "<!here> can everyone review this?"
      {_blocks, mentions, _links} = RichTextProcessor.process(content)

      assert length(mentions) == 1
      mention = hd(mentions)
      assert mention["type"] == "special_mention"
      assert mention["mention"] == "here"
    end

    test "processes code blocks" do
      content = "```\nconst x = 1;\nconsole.log(x);\n```"
      {blocks, _mentions, _links} = RichTextProcessor.process(content)

      code_blocks = Enum.filter(blocks, &(&1["type"] == "code"))
      assert length(code_blocks) == 1
      assert hd(code_blocks)["text"] =~ "const x = 1;"
    end

    test "processes block quotes" do
      content = "> This is a quote\n> Multi-line quote"
      {blocks, _mentions, _links} = RichTextProcessor.process(content)

      quote_blocks = Enum.filter(blocks, &(&1["type"] == "quote"))
      assert length(quote_blocks) == 2
    end

    test "processes headers" do
      content = "# Header 1\n## Header 2\n### Header 3"
      {blocks, _mentions, _links} = RichTextProcessor.process(content)

      header_blocks = Enum.filter(blocks, &(&1["type"] == "header"))
      assert length(header_blocks) == 3

      h1 = Enum.find(header_blocks, &(&1["level"] == 1))
      assert h1["text"]["text"] == "Header 1"
    end

    test "processes complex message with multiple elements" do
      content = """
      Hey <@123|John>, check out <https://wecraft.dev|WeCraft> :rocket:

      > This looks amazing!

      ```
      def hello_world
        puts "Hello!"
      end
      ```

      <!here> what do you think?
      """

      {blocks, mentions, links} = RichTextProcessor.process(content)

      # Should have multiple blocks
      assert length(blocks) > 3

      # Should extract mentions
      # user mention + special mention
      assert length(mentions) == 2
      user_mention = Enum.find(mentions, &(&1["type"] == "user"))
      assert user_mention["user_id"] == "123"

      special_mention = Enum.find(mentions, &(&1["type"] == "special_mention"))
      assert special_mention["mention"] == "here"

      # Should extract links
      assert length(links) == 1
      link = hd(links)
      assert link["url"] == "https://wecraft.dev"
    end
  end

  describe "blocks_to_html/1" do
    test "converts section blocks to HTML" do
      blocks = [
        %{
          "type" => "section",
          "text" => %{"text" => "Hello <@123|John>"},
          "elements" => [
            %{
              "type" => "user",
              "user_id" => "123",
              "display_name" => "John"
            }
          ]
        }
      ]

      html = RichTextProcessor.blocks_to_html(blocks)
      assert html =~ "<div class=\"message-section\">"
      assert html =~ "Hello"
    end

    test "converts header blocks to HTML" do
      blocks = [
        %{
          "type" => "header",
          "level" => 1,
          "text" => %{"text" => "Main Header"}
        }
      ]

      html = RichTextProcessor.blocks_to_html(blocks)
      assert html =~ "<h1 class=\"message-header\">"
      assert html =~ "Main Header"
    end

    test "converts code blocks to HTML" do
      blocks = [
        %{
          "type" => "code",
          "text" => "const x = 1;\nconsole.log(x);"
        }
      ]

      html = RichTextProcessor.blocks_to_html(blocks)
      assert html =~ "<pre class=\"message-code\">"
      assert html =~ "<code>"
      assert html =~ "const x = 1;"
    end

    test "converts quote blocks to HTML" do
      blocks = [
        %{
          "type" => "quote",
          "text" => "This is a quote"
        }
      ]

      html = RichTextProcessor.blocks_to_html(blocks)
      assert html =~ "<blockquote class=\"message-quote\">"
      assert html =~ "This is a quote"
    end
  end

  describe "extract_mentions/1" do
    test "extracts all types of mentions" do
      content = "Hey <@123|John> and <#456|general>, <!here> is an update"
      mentions = RichTextProcessor.extract_mentions(content)

      assert length(mentions) == 3

      user_mention = Enum.find(mentions, &(&1["type"] == "user"))
      assert user_mention["user_id"] == "123"

      channel_mention = Enum.find(mentions, &(&1["type"] == "channel"))
      assert channel_mention["channel_id"] == "456"

      special_mention = Enum.find(mentions, &(&1["type"] == "special_mention"))
      assert special_mention["mention"] == "here"
    end
  end

  describe "extract_links/1" do
    test "extracts explicit and auto-detected links" do
      content = """
      Check out <https://wecraft.dev|WeCraft> and also visit https://github.com/wecraft
      Email us at <mailto:hello@wecraft.dev|contact us>
      """

      links = RichTextProcessor.extract_links(content)

      assert length(links) == 3

      explicit_link = Enum.find(links, &(&1["type"] == "link"))
      assert explicit_link["url"] == "https://wecraft.dev"
      assert explicit_link["display_text"] == "WeCraft"

      auto_link = Enum.find(links, &(&1["type"] == "auto_link"))
      assert auto_link["url"] == "https://github.com/wecraft"

      email_link = Enum.find(links, &(&1["type"] == "email"))
      assert email_link["email"] == "hello@wecraft.dev"
    end
  end
end
