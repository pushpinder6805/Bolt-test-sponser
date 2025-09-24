import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "add-promote-button",
  
  initialize() {
    console.log("Promote button initializer running...");
    
    withPluginApi("0.8.31", (api) => {
      console.log("Plugin API available, adding promote button...");
      
      // Add button to post admin menu
      api.addPostAdminMenuButton((post) => {
        return {
          action: "promotePost",
          icon: "bullhorn",
          label: "sponsored_posts.promote_post",
          className: "promote-post-btn"
        };
      });

      // Handle the action
      api.modifyClass("controller:topic", {
        pluginId: "discourse-sponsored-posts",
        
        actions: {
          promotePost(post) {
            this.modal.show("sponsor-post", { model: post });
          }
        }
      });
    });
  },
};
