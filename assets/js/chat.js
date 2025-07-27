// Chat functionality for auto-scrolling to the bottom
const chatScroll = {
  mounted() {
    this.scrollToBottom();
    this.observer = new MutationObserver(() => this.scrollToBottom());
    this.observer.observe(this.el, { childList: true, subtree: true });
  },

  destroyed() {
    if (this.observer) {
      this.observer.disconnect();
    }
  },

  scrollToBottom() {
    this.el.scrollTop = this.el.scrollHeight;
  },
};

export { chatScroll };
