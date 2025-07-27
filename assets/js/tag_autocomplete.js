// Tag autocomplete hooks
export const tagAutocomplete = {
  mounted() {
    this.inputField = this.el.querySelector("input");
    this.suggestionsContainer = this.el.querySelector(
      ".autocomplete-suggestions"
    );

    if (this.inputField && this.suggestionsContainer) {
      // Show suggestions when input is focused
      this.inputField.addEventListener("focus", () => {
        this.showSuggestions();
      });

      // Hide suggestions when clicking outside
      document.addEventListener("click", (e) => {
        if (!this.el.contains(e.target)) {
          this.hideSuggestions();
        }
      });

      // Handle input changes to filter suggestions
      this.inputField.addEventListener("input", (e) => {
        this.showSuggestions();

        // Send the value to the server for filtering
        this.pushEventTo(
          this.el.getAttribute("phx-target"),
          "handle_tag_input",
          {
            value: e.target.value,
            field: this.inputField.getAttribute("phx-value-field"),
            category: this.inputField.getAttribute("phx-value-category"),
          }
        );
      });

      // Handle key events (arrow navigation, enter selection)
      this.inputField.addEventListener("keydown", (e) => {
        if (e.key === "Enter" || e.key === "Tab") {
          e.preventDefault();

          if (this.inputField.value.trim() !== "") {
            // Send the value to be added as a tag
            this.pushEventTo(
              this.el.getAttribute("phx-target"),
              "handle_tag_input",
              {
                key: e.key,
                value: this.inputField.value.trim(),
                field: this.inputField.getAttribute("phx-value-field"),
                category: this.inputField.getAttribute("phx-value-category"),
              }
            );

            // Clear the input field
            this.inputField.value = "";
          }
        } else if (e.key === "Escape") {
          this.hideSuggestions();
        }
      });
    }
  },

  updated() {
    // This ensures the suggestions list updates when the filtered options change
    if (this.inputField === document.activeElement) {
      this.showSuggestions();
    }
  },

  showSuggestions() {
    if (this.suggestionsContainer) {
      this.suggestionsContainer.classList.remove("hidden");
    }
  },

  hideSuggestions() {
    if (this.suggestionsContainer) {
      this.suggestionsContainer.classList.add("hidden");
    }
  },
};
