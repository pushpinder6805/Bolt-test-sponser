# frozen_string_literal: true

# name: discourse-sponsored-posts
# about: Allow users to sponsor posts with payments via Stripe/PayPal
# version: 0.1
# authors: Pushpender
# required_version: 3.3.0

enabled_site_setting :sponsored_posts_enabled

PLUGIN_NAME ||= "discourse-sponsored-posts".freeze

register_asset "stylesheets/common/sponsored.scss"
register_asset "javascripts/discourse/initializers/add-promote-button.js", :client_side

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
    "#{Rails.root}/plugins/discourse-sponsored-posts/app/controllers/admin/sponsored_posts_controller",
    "#{Rails.root}/plugins/discourse-sponsored-posts/app/controllers/sponsored/posts_controller"
  ].each { |path| load "#{path}.rb" }

  # Register route
  Discourse::Application.routes.append do
    namespace :sponsored do
      post "/create" => "posts#create"
    end
  end

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

register_asset_filter do |type, request, assets|
  if type == :script
    assets << "https://js.stripe.com"
    assets << "https://www.paypal.com"
  elsif type == :connect
    assets << "https://api.stripe.com"
    assets << "https://api.paypal.com"
    assets << "https://api-m.sandbox.paypal.com"
  end
end
