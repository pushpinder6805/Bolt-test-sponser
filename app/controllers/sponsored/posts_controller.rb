# app/controllers/sponsored/posts_controller.rb
module Sponsored
  class PostsController < ::ApplicationController
    def create
      render json: { ok: true }
    end

    def stats
      render json: { impressions: 0, clicks: 0 }
    end

    def index
      render json: SponsoredPost.all
    end

    def export
      render plain: "Export not implemented", status: 501
    end
  end
end

