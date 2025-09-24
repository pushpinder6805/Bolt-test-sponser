# frozen_string_literal: true

module Sponsored
  class PaymentsController < ApplicationController
    requires_plugin 'discourse-sponsored-posts'
    before_action :ensure_logged_in

    def checkout
      return render_json_error("Sponsored posts not enabled", status: 403) unless SiteSetting.sponsored_posts_enabled
      return render_json_error("Payments not enabled", status: 403) unless SiteSetting.sponsored_payments_enabled
      return render_json_error("Not eligible to sponsor posts", status: 403) unless Sponsored::Eligibility.allowed?(current_user)

      post = Post.find_by(id: params[:post_id])
      return render_json_error("Post not found", status: 404) unless post
      return render_json_error("Not authorized", status: 403) unless post.user_id == current_user.id
      
      days = params[:days].to_i
      allowed_durations = SiteSetting.sponsored_durations_days.split("|").map(&:to_i)
      return render_json_error("Invalid duration", status: 400) unless allowed_durations.include?(days)
      
      provider = params[:provider]
      return render_json_error("Invalid provider", status: 400) unless %w[stripe paypal].include?(provider)

      # Check user limits
      active_count = SponsoredPost.active_now.where(user_id: current_user.id).count
      return render_json_error("Maximum active sponsored posts reached", status: 400) if active_count >= SiteSetting.sponsored_max_active_per_user

      # Create pending record
      sp = SponsoredPost.create!(
        post_id: post.id,
        user_id: current_user.id,
        starts_at: Time.zone.now,
        expires_at: Time.zone.now + days.days,
        active: !SiteSetting.sponsored_require_moderation,
        provider: provider,
        impressions: 0,
        clicks: 0,
        likes: 0,
        replies: 0
      )

      # Notify admins if moderation required
      if SiteSetting.sponsored_require_moderation
        Sponsored::Notifier.notify_admins(sp)
      end

      render_json_dump(
        success: true, 
        sponsored_post_id: sp.id,
        requires_approval: SiteSetting.sponsored_require_moderation
      )
    rescue ActiveRecord::RecordInvalid => e
      render_json_error(e.message, status: 422)
    rescue => e
      Rails.logger.error "Sponsored post checkout error: #{e.message}"
      render_json_error("An error occurred", status: 500)
    end
  end
end