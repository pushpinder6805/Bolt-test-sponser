# frozen_string_literal: true

module Sponsored
  class EventsController < ApplicationController
    requires_plugin 'discourse-sponsored-posts'

    def track
      return render_json_error("Sponsored posts not enabled", status: 403) unless SiteSetting.sponsored_posts_enabled

      sp_id = params[:sponsored_post_id]
      event_type = params[:event_type]

      return render_json_error("Missing parameters", status: 400) unless sp_id && event_type

      sp = SponsoredPost.find_by(id: sp_id)
      return render_json_error("Sponsored post not found", status: 404) unless sp

      Sponsored::StatService.bump(sp, event_type)
      render_json_dump(success: true)
    rescue => e
      Rails.logger.error "Event tracking error: #{e.message}"
      render_json_error("An error occurred", status: 500)
    end
  end
end