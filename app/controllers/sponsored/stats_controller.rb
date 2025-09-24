# frozen_string_literal: true

module Sponsored
  class StatsController < ApplicationController
    requires_plugin 'discourse-sponsored-posts'
    before_action :ensure_logged_in

    def show
      sp = SponsoredPost.find_by(id: params[:id])
      return render_json_error("Not found", status: 404) unless sp
      return render_json_error("Not authorized", status: 403) unless sp.user_id == current_user.id

      render_json_dump(SponsoredPostSerializer.new(sp, root: false).as_json)
    rescue => e
      Rails.logger.error "Stats error: #{e.message}"
      render_json_error("An error occurred", status: 500)
    end
  end
end