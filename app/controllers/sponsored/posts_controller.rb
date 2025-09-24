module Sponsored
  class PostsController < ::ApplicationController
    PLUGIN_NAME = "discourse-sponsored-posts"
    before_action :ensure_logged_in

    def create
      post = Post.find_by(id: params[:post_id])
      raise Discourse::NotFound unless post

      days = params[:days].to_i
      expires_at = Time.zone.now + days.days

      sp = SponsoredPost.create!(
        post_id: post.id,
        user_id: current_user.id,
        starts_at: Time.zone.now,
        expires_at: expires_at,
        active: false
      )

      # TODO: Redirect to payment (Stripe/PayPal)
      render json: { success: true, sponsored_post_id: sp.id }
    end
  end
end
