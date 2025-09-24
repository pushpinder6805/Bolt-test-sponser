# frozen_string_literal: true

# name: discourse-sponsored-posts
# about: Allow users to sponsor posts with payments via Stripe/PayPal
# version: 0.1
# authors: Pushpender
# required_version: 3.3.0

enabled_site_setting :sponsored_posts_enabled

PLUGIN_NAME ||= "discourse-sponsored-posts".freeze

register_asset "stylesheets/common/sponsored.scss"

after_initialize do
  # Load models and services
  [
    "#{Rails.root}/plugins/discourse-sponsored-posts/app/models/sponsored_post",
    "#{Rails.root}/plugins/discourse-sponsored-posts/app/models/sponsored_event",
    "#{Rails.root}/plugins/discourse-sponsored-posts/app/serializers/sponsored_post_serializer",
    "#{Rails.root}/plugins/discourse-sponsored-posts/services/sponsored/eligibility",
    "#{Rails.root}/plugins/discourse-sponsored-posts/services/sponsored/notifier",
    "#{Rails.root}/plugins/discourse-sponsored-posts/services/sponsored/rotator",
    "#{Rails.root}/plugins/discourse-sponsored-posts/services/sponsored/stat_service"
  ].each { |path| load "#{path}.rb" }

  # Load controllers
  [
    "#{Rails.root}/plugins/discourse-sponsored-posts/app/controllers/sponsored/payments_controller",
    "#{Rails.root}/plugins/discourse-sponsored-posts/app/controllers/sponsored/webhooks_controller",
    "#{Rails.root}/plugins/discourse-sponsored-posts/app/controllers/admin/sponsored_posts_controller"
  ].each { |path| load "#{path}.rb" }

  # Inject into topic lists (server-side data source for sponsored posts)
  add_to_serializer(:topic_list, :sponsored_pool) do
    return [] unless SiteSetting.sponsored_posts_enabled
    
    SponsoredPost.active_now
      .order("updated_at desc")
      .limit(50)
      .includes(:post, :user)
      .map { |sp| SponsoredPostSerializer.new(sp, root: false).as_json }
  end

  # Add sponsored post data to post serializer
  add_to_serializer(:post, :is_sponsored) do
    SponsoredPost.active_now.exists?(post_id: object.id)
  end

  add_to_serializer(:post, :sponsored_data) do
    return nil unless is_sponsored
    
    sp = SponsoredPost.active_now.find_by(post_id: object.id)
    return nil unless sp
    
    SponsoredPostSerializer.new(sp, root: false).as_json
  end

  # Add user permissions
  add_to_serializer(:current_user, :can_sponsor_posts) do
    Sponsored::Eligibility.allowed?(object)
  end
end

# Register CSP extensions for payment providers
register_csp_extension do |csp|
  csp[:script_src] << 'https://js.stripe.com'
  csp[:script_src] << 'https://www.paypal.com'
  csp[:connect_src] << 'https://api.stripe.com'
  csp[:connect_src] << 'https://api.paypal.com'
  csp[:connect_src] << 'https://api-m.sandbox.paypal.com'
end