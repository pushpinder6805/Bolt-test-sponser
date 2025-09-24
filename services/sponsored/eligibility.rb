# frozen_string_literal: true

module Sponsored
  class Eligibility
    def self.allowed?(user)
      return false unless SiteSetting.sponsored_posts_enabled
      return false unless user
      
      # Check trust level
      allowed_tls = SiteSetting.sponsored_allowed_trust_levels.split("|").map(&:to_i)
      tl_ok = allowed_tls.include?(user.trust_level)
      
      # Check groups
      allowed_groups = SiteSetting.sponsored_allowed_groups.split("|").reject(&:blank?)
      groups_ok = allowed_groups.empty? || user.groups.where(name: allowed_groups).exists?
      
      # Check account age
      min_age = SiteSetting.sponsored_min_account_age_days.days.ago
      age_ok = user.created_at <= min_age
      
      # Check if user is suspended or silenced
      user_ok = !user.suspended? && !user.silenced?
      
      tl_ok && groups_ok && age_ok && user_ok
    end

    def self.can_sponsor_post?(user, post)
      return false unless allowed?(user)
      return false unless post
      return false unless post.user_id == user.id
      
      # Check if post is already sponsored
      return false if SponsoredPost.active_now.exists?(post_id: post.id)
      
      # Check user's active sponsored posts limit
      active_count = SponsoredPost.active_now.where(user_id: user.id).count
      return false if active_count >= SiteSetting.sponsored_max_active_per_user
      
      true
    end
  end
end