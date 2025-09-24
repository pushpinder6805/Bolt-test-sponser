import { withPluginApi } from "discourse/lib/plugin-api";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import showModal from "discourse/lib/show-modal";
import I18n from "discourse-i18n";

export default {
  name: "sponsored-ui",
  initialize() {
    withPluginApi("1.22.0", (api) => {
      // Post menu action
      api.addPostMenuButton("promote-post", (attrs) => {
        if (!attrs.currentUser?.can_sponsor_posts) return null;
        if (!attrs.post || attrs.post.user_id !== attrs.currentUser.id) return null;
        if (attrs.post.is_sponsored) return null;

        return {
          action: "sponsorPost",
          icon: "bullhorn",
          className: "sponsor-post-btn",
          title: I18n.t("sponsored.promote"),
          label: I18n.t("sponsored.promote"),
        };
      });

      api.attachWidgetAction("post-menu", "sponsorPost", function () {
        const post = this.attrs.post;
        showModal("sponsor-post", { model: { post } });
      });

      // Add sponsored label to posts
      api.decorateWidget("post-contents:before", (dec) => {
        if (!dec.attrs.post?.is_sponsored) return;
        
        const labelText = dec.siteSettings.sponsored_label_text || "Sponsored";
        const tooltipUrl = dec.siteSettings.sponsored_label_tooltip_url || "/tos";
        
        return dec.h("div.sponsored-post-label", [
          dec.h("span.sponsored-label", labelText),
          dec.h("a.sponsored-info", { 
            href: tooltipUrl, 
            title: I18n.t("sponsored.tooltip"),
            target: "_blank"
          }, "ⓘ")
        ]);
      });

      // Track impressions when posts become visible
      api.onPageChange(() => {
        setTimeout(() => {
          trackVisibleSponsoredPosts();
        }, 1000);
      });

      // Track clicks on sponsored posts
      api.decorateWidget("post", (dec) => {
        if (!dec.attrs.post?.is_sponsored) return;
        
        return dec.attach("button", {
          className: "sponsored-click-tracker",
          action: "trackSponsoredClick",
          style: "display: none;"
        });
      });

      api.attachWidgetAction("post", "trackSponsoredClick", function() {
        const post = this.attrs.post;
        if (post?.sponsored_data?.id) {
          trackSponsoredEvent(post.sponsored_data.id, "click");
        }
      });

      // Add click tracking to post links
      api.onAppEvent("post:highlight", (postElement) => {
        const post = postElement.closest(".topic-post");
        if (!post) return;
        
        const postId = post.dataset.postId;
        const postData = api.container.lookup("controller:topic").get("model.postStream.posts")
          .find(p => p.id == postId);
          
        if (postData?.is_sponsored && postData.sponsored_data?.id) {
          post.addEventListener("click", () => {
            trackSponsoredEvent(postData.sponsored_data.id, "click");
          });
        }
      });

      function trackVisibleSponsoredPosts() {
        const visiblePosts = document.querySelectorAll(".topic-post:not(.sponsored-impression-tracked)");
        
        visiblePosts.forEach(postElement => {
          const rect = postElement.getBoundingClientRect();
          const isVisible = rect.top >= 0 && rect.top <= window.innerHeight;
          
          if (isVisible) {
            const postId = postElement.dataset.postId;
            const controller = api.container.lookup("controller:topic");
            const post = controller.get("model.postStream.posts").find(p => p.id == postId);
            
            if (post?.is_sponsored && post.sponsored_data?.id) {
              trackSponsoredEvent(post.sponsored_data.id, "impression");
              postElement.classList.add("sponsored-impression-tracked");
            }
          }
        });
      }

      function trackSponsoredEvent(sponsoredPostId, eventType) {
        ajax("/sponsored/events", {
          type: "POST",
          data: {
            sponsored_post_id: sponsoredPostId,
            event_type: eventType
          }
        }).catch(popupAjaxError);
      }
    });
  },
};