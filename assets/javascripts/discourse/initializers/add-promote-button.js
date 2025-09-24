console.log("✅ add-promote-button.js loaded");

import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "add-promote-button",

  initialize(container) {
    withPluginApi("0.11.1", api => {
      api.decorateWidget("post-menu:after", helper => {
        const currentUser = helper.currentUser;
        const post = helper.getModel();

        if (!currentUser) return;

        return helper.h(
          "button.promote-post-btn",
          {
            onclick: () => {
              const days = prompt("How many days to promote this post?");
              if (!days) return;

              fetch(`/sponsored/create`, {
                method: "POST",
                headers: {
                  "Content-Type": "application/json",
                  "X-CSRF-Token": api.csrfToken()
                },
                body: JSON.stringify({
                  post_id: post.id,
                  days: parseInt(days, 10)
                })
              }).then(() => {
                alert("Promotion request submitted.");
              });
            }
          },
          "Promote"
        );
      });
    });
  }
};
