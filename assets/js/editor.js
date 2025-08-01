// Chat functionality for auto-scrolling to the bottom
const editor = {
  mounted() {
    const content = JSON.parse(this.el.dataset.content || "{}");
    console.log(content);
    this.editor = new EditorJS({
      holder: this.el,
      data: { blocks: content },
      onChange: async () => {
        const content = await this.editor.save();
        this.pushEvent("editor-update", content);
      },
      tools: {
        warning: Warning,
        delimiter: Delimiter,
        underline: Underline,
        image: {
          class: ImageTool,
          config: {
            endpoints: {
              byFile: "http://localhost:8008/uploadFile", // Your backend file uploader endpoint
              byUrl: "http://localhost:8008/fetchUrl", // Your endpoint that provides uploading by Url
            },
          },
        },
        paragraph: {
          class: Paragraph,
          inlineToolbar: true,
          config: {
            placeholder: "Type your text here...",
          },
        },
        code: CodeTool,
        header: Header,
        quote: Quote,
        inlineCode: {
          class: InlineCode,
          shortcut: "CMD+SHIFT+M",
        },
        table: Table,
        List: {
          class: EditorjsList,
          inlineToolbar: true,
          config: {
            defaultStyle: "unordered",
          },
        },
        //list: List,
      },
    });
  },
};

export { editor };
