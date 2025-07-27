export const CreateRoomHook = {
  mounted() {
    const domain = window.jitsiUrl;
    const options = {
      roomName: this.el.dataset.roomName,
      width: this.el.innerWidth,
      height: this.el.innerHeight,
      parentNode: this.el,
      lang: "fr",
      userInfo: {
        email: this.el.dataset.userEmail,
        displayName: this.el.dataset.userName,
      },
    };

    const api = new JitsiMeetExternalAPI(domain, options);
    // Listen for the conference left event
    api.addEventListener("videoConferenceLeft", () => {
      // Redirect user when the meeting ends
      const redirectUrl = this.el.dataset.redirectUrl;
      window.location.href = redirectUrl;
    });
  },
};
