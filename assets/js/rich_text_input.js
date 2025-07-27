/**
 * Rich Text Input Handler for Slack-like message formatting
 * Handles mentions, links, and other rich content in real-time
 */

class RichTextInput {
  constructor(inputElement, options = {}) {
    this.input = inputElement;
    this.options = {
      enableMentions: true,
      enableEmojis: true,
      enableAutoLinks: true,
      mentionTrigger: "@",
      emojiTrigger: ":",
      ...options,
    };

    this.mentionPopup = null;
    this.emojiPopup = null;
    this.users = [];
    this.channels = [];

    this.init();
  }

  init() {
    this.setupEventListeners();
    this.createPopupElements();
  }

  setupEventListeners() {
    this.input.addEventListener("input", this.handleInput.bind(this));
    this.input.addEventListener("keydown", this.handleKeydown.bind(this));
    this.input.addEventListener("keyup", this.handleKeyup.bind(this));
    this.input.addEventListener("paste", this.handlePaste.bind(this));
  }

  handleInput(event) {
    const value = event.target.value;
    const cursorPosition = event.target.selectionStart;

    // Check for mention trigger
    if (this.options.enableMentions) {
      this.checkForMentions(value, cursorPosition);
    }

    // Check for emoji trigger
    if (this.options.enableEmojis) {
      this.checkForEmojis(value, cursorPosition);
    }

    // Auto-detect URLs
    if (this.options.enableAutoLinks) {
      this.highlightUrls(value);
    }
  }

  handleKeydown(event) {
    // Handle special keys when popups are open
    if (this.mentionPopup && this.mentionPopup.isVisible()) {
      this.handleMentionKeydown(event);
    } else if (this.emojiPopup && this.emojiPopup.isVisible()) {
      this.handleEmojiKeydown(event);
    }
  }

  handleKeyup(event) {
    // Additional processing after key release
  }

  handlePaste(event) {
    // Process pasted content for rich formatting
    const pastedText = (event.clipboardData || window.clipboardData).getData(
      "text"
    );

    // Convert URLs to link format
    const processedText = this.processLinksInText(pastedText);

    if (processedText !== pastedText) {
      event.preventDefault();
      this.insertTextAtCursor(processedText);
    }
  }

  checkForMentions(value, cursorPosition) {
    const textBeforeCursor = value.substring(0, cursorPosition);
    const mentionMatch = textBeforeCursor.match(/@([a-zA-Z0-9_]*)$/);

    if (mentionMatch) {
      const query = mentionMatch[1];
      this.showMentionPopup(query, cursorPosition - mentionMatch[0].length);
    } else {
      this.hideMentionPopup();
    }
  }

  checkForEmojis(value, cursorPosition) {
    const textBeforeCursor = value.substring(0, cursorPosition);
    const emojiMatch = textBeforeCursor.match(/:([a-zA-Z0-9_+-]*)$/);

    if (emojiMatch) {
      const query = emojiMatch[1];
      this.showEmojiPopup(query, cursorPosition - emojiMatch[0].length);
    } else {
      this.hideEmojiPopup();
    }
  }

  showMentionPopup(query, position) {
    // Filter users based on query
    const filteredUsers = this.users.filter(
      (user) =>
        user.name.toLowerCase().includes(query.toLowerCase()) ||
        user.email.toLowerCase().includes(query.toLowerCase())
    );

    if (filteredUsers.length > 0) {
      this.mentionPopup.show(filteredUsers, position);
    } else {
      this.hideMentionPopup();
    }
  }

  showEmojiPopup(query, position) {
    // Filter emojis based on query
    const filteredEmojis = this.getEmojiSuggestions(query);

    if (filteredEmojis.length > 0) {
      this.emojiPopup.show(filteredEmojis, position);
    } else {
      this.hideEmojiPopup();
    }
  }

  hideMentionPopup() {
    if (this.mentionPopup) {
      this.mentionPopup.hide();
    }
  }

  hideEmojiPopup() {
    if (this.emojiPopup) {
      this.emojiPopup.hide();
    }
  }

  insertMention(user) {
    const value = this.input.value;
    const cursorPosition = this.input.selectionStart;
    const textBeforeCursor = value.substring(0, cursorPosition);
    const textAfterCursor = value.substring(cursorPosition);

    // Find the @ symbol and replace the partial mention
    const mentionMatch = textBeforeCursor.match(/@([a-zA-Z0-9_]*)$/);
    if (mentionMatch) {
      const beforeMention = textBeforeCursor.substring(
        0,
        textBeforeCursor.length - mentionMatch[0].length
      );
      const mentionText = `<@${user.id}|${user.name}>`;
      const newValue = beforeMention + mentionText + textAfterCursor;

      this.input.value = newValue;
      this.input.selectionStart = this.input.selectionEnd =
        beforeMention.length + mentionText.length;
    }

    this.hideMentionPopup();
    this.input.focus();
  }

  insertEmoji(emoji) {
    const value = this.input.value;
    const cursorPosition = this.input.selectionStart;
    const textBeforeCursor = value.substring(0, cursorPosition);
    const textAfterCursor = value.substring(cursorPosition);

    // Find the : symbol and replace the partial emoji
    const emojiMatch = textBeforeCursor.match(/:([a-zA-Z0-9_+-]*)$/);
    if (emojiMatch) {
      const beforeEmoji = textBeforeCursor.substring(
        0,
        textBeforeCursor.length - emojiMatch[0].length
      );
      const emojiText = `:${emoji.name}:`;
      const newValue = beforeEmoji + emojiText + textAfterCursor;

      this.input.value = newValue;
      this.input.selectionStart = this.input.selectionEnd =
        beforeEmoji.length + emojiText.length;
    }

    this.hideEmojiPopup();
    this.input.focus();
  }

  processLinksInText(text) {
    // Convert bare URLs to Slack link format
    const urlRegex = /(https?:\/\/[^\s]+)/g;
    return text.replace(urlRegex, "<$1>");
  }

  highlightUrls(text) {
    // Visual highlighting of URLs in the input (would need custom implementation)
    // This is more complex and typically requires a rich text editor
  }

  insertTextAtCursor(text) {
    const cursorPosition = this.input.selectionStart;
    const currentValue = this.input.value;
    const newValue =
      currentValue.substring(0, cursorPosition) +
      text +
      currentValue.substring(this.input.selectionEnd);

    this.input.value = newValue;
    this.input.selectionStart = this.input.selectionEnd =
      cursorPosition + text.length;
  }

  createPopupElements() {
    this.mentionPopup = new MentionPopup(this.input, this);
    this.emojiPopup = new EmojiPopup(this.input, this);
  }

  setUsers(users) {
    this.users = users;
  }

  setChannels(channels) {
    this.channels = channels;
  }

  getEmojiSuggestions(query) {
    const commonEmojis = [
      { name: "smile", unicode: "😄" },
      { name: "heart", unicode: "❤️" },
      { name: "thumbsup", unicode: "👍" },
      { name: "thumbsdown", unicode: "👎" },
      { name: "fire", unicode: "🔥" },
      { name: "rocket", unicode: "🚀" },
      { name: "wave", unicode: "👋" },
      { name: "eyes", unicode: "👀" },
      { name: "clap", unicode: "👏" },
      { name: "tada", unicode: "🎉" },
    ];

    return commonEmojis.filter((emoji) =>
      emoji.name.toLowerCase().includes(query.toLowerCase())
    );
  }
}

class MentionPopup {
  constructor(inputElement, richTextInput) {
    this.input = inputElement;
    this.richTextInput = richTextInput;
    this.popup = this.createElement();
    this.visible = false;
    this.selectedIndex = 0;
  }

  createElement() {
    const popup = document.createElement("div");
    popup.className =
      "mention-popup absolute bg-white border border-gray-300 rounded-md shadow-lg z-50 max-h-48 overflow-y-auto hidden";
    popup.style.minWidth = "200px";

    // Position it near the input
    document.body.appendChild(popup);

    return popup;
  }

  show(users, position) {
    this.users = users;
    this.selectedIndex = 0;
    this.render();
    this.position();
    this.popup.classList.remove("hidden");
    this.visible = true;
  }

  hide() {
    this.popup.classList.add("hidden");
    this.visible = false;
  }

  isVisible() {
    return this.visible;
  }

  render() {
    this.popup.innerHTML = "";

    this.users.forEach((user, index) => {
      const item = document.createElement("div");
      item.className = `mention-item px-3 py-2 cursor-pointer hover:bg-gray-100 ${
        index === this.selectedIndex ? "bg-blue-100" : ""
      }`;
      item.innerHTML = `
        <div class="flex items-center">
          <div class="w-6 h-6 bg-blue-500 rounded-full flex items-center justify-center text-white text-xs font-bold mr-2">
            ${user.name.charAt(0).toUpperCase()}
          </div>
          <div>
            <div class="font-medium">${user.name}</div>
            <div class="text-sm text-gray-500">${user.email}</div>
          </div>
        </div>
      `;

      item.addEventListener("click", () => {
        this.richTextInput.insertMention(user);
      });

      this.popup.appendChild(item);
    });
  }

  position() {
    const inputRect = this.input.getBoundingClientRect();
    this.popup.style.left = `${inputRect.left}px`;
    this.popup.style.top = `${inputRect.bottom + 5}px`;
  }

  selectNext() {
    this.selectedIndex = Math.min(
      this.selectedIndex + 1,
      this.users.length - 1
    );
    this.render();
  }

  selectPrevious() {
    this.selectedIndex = Math.max(this.selectedIndex - 1, 0);
    this.render();
  }

  selectCurrent() {
    if (this.users[this.selectedIndex]) {
      this.richTextInput.insertMention(this.users[this.selectedIndex]);
    }
  }
}

class EmojiPopup {
  constructor(inputElement, richTextInput) {
    this.input = inputElement;
    this.richTextInput = richTextInput;
    this.popup = this.createElement();
    this.visible = false;
    this.selectedIndex = 0;
  }

  createElement() {
    const popup = document.createElement("div");
    popup.className =
      "emoji-popup absolute bg-white border border-gray-300 rounded-md shadow-lg z-50 max-h-48 overflow-y-auto hidden";
    popup.style.minWidth = "200px";

    document.body.appendChild(popup);

    return popup;
  }

  show(emojis, position) {
    this.emojis = emojis;
    this.selectedIndex = 0;
    this.render();
    this.position();
    this.popup.classList.remove("hidden");
    this.visible = true;
  }

  hide() {
    this.popup.classList.add("hidden");
    this.visible = false;
  }

  isVisible() {
    return this.visible;
  }

  render() {
    this.popup.innerHTML = "";

    this.emojis.forEach((emoji, index) => {
      const item = document.createElement("div");
      item.className = `emoji-item px-3 py-2 cursor-pointer hover:bg-gray-100 flex items-center ${
        index === this.selectedIndex ? "bg-blue-100" : ""
      }`;
      item.innerHTML = `
        <span class="text-lg mr-2">${emoji.unicode}</span>
        <span>:${emoji.name}:</span>
      `;

      item.addEventListener("click", () => {
        this.richTextInput.insertEmoji(emoji);
      });

      this.popup.appendChild(item);
    });
  }

  position() {
    const inputRect = this.input.getBoundingClientRect();
    this.popup.style.left = `${inputRect.left}px`;
    this.popup.style.top = `${inputRect.bottom + 5}px`;
  }

  selectNext() {
    this.selectedIndex = Math.min(
      this.selectedIndex + 1,
      this.emojis.length - 1
    );
    this.render();
  }

  selectPrevious() {
    this.selectedIndex = Math.max(this.selectedIndex - 1, 0);
    this.render();
  }

  selectCurrent() {
    if (this.emojis[this.selectedIndex]) {
      this.richTextInput.insertEmoji(this.emojis[this.selectedIndex]);
    }
  }
}

// Export for use in Phoenix LiveView
window.RichTextInput = RichTextInput;

// Phoenix Hook for LiveView integration
window.RichTextHook = {
  mounted() {
    this.richTextInput = new RichTextInput(this.el, {
      enableMentions: true,
      enableEmojis: true,
      enableAutoLinks: true,
    });

    // Load users from LiveView assigns or API
    this.handleEvent("load_users", (data) => {
      this.richTextInput.setUsers(data.users);
    });

    // Handle mention and emoji key navigation
    this.el.addEventListener("keydown", (event) => {
      if (
        this.richTextInput.mentionPopup &&
        this.richTextInput.mentionPopup.isVisible()
      ) {
        if (event.key === "ArrowDown") {
          event.preventDefault();
          this.richTextInput.mentionPopup.selectNext();
        } else if (event.key === "ArrowUp") {
          event.preventDefault();
          this.richTextInput.mentionPopup.selectPrevious();
        } else if (event.key === "Enter" || event.key === "Tab") {
          event.preventDefault();
          this.richTextInput.mentionPopup.selectCurrent();
        } else if (event.key === "Escape") {
          this.richTextInput.hideMentionPopup();
        }
      }

      if (
        this.richTextInput.emojiPopup &&
        this.richTextInput.emojiPopup.isVisible()
      ) {
        if (event.key === "ArrowDown") {
          event.preventDefault();
          this.richTextInput.emojiPopup.selectNext();
        } else if (event.key === "ArrowUp") {
          event.preventDefault();
          this.richTextInput.emojiPopup.selectPrevious();
        } else if (event.key === "Enter" || event.key === "Tab") {
          event.preventDefault();
          this.richTextInput.emojiPopup.selectCurrent();
        } else if (event.key === "Escape") {
          this.richTextInput.hideEmojiPopup();
        }
      }
    });
  },

  destroyed() {
    if (this.richTextInput) {
      // Clean up popup elements
      if (this.richTextInput.mentionPopup) {
        this.richTextInput.mentionPopup.popup.remove();
      }
      if (this.richTextInput.emojiPopup) {
        this.richTextInput.emojiPopup.popup.remove();
      }
    }
  },
};
