# frozen_string_literal: true

class Admin::SponsoredPostsController < Admin::AdminController
  requires_plugin 'discourse-sponsored-posts'

  def index
    sponsored_posts = SponsoredPost.includes(:post, :user)
                                   .order(created_at: :desc)
                                   .limit(50)

    render_serialized(sponsored_posts, SponsoredPostSerializer, root: 'sponsored_posts')
  end

  def show
    sp = SponsoredPost.find(params[:id])
    render_serialized(sp, SponsoredPostSerializer, root: false)
  end

  def approve
    sp = SponsoredPost.find(params[:id])
    sp.update!(active: true)
    render_json_dump(success: true)
  end

  def reject
    sp = SponsoredPost.find(params[:id])
    sp.update!(active: false)
    render_json_dump(success: true)
  end

  def destroy
    sp = SponsoredPost.find(params[:id])
    sp.destroy!
    render_json_dump(success: true)
  end
end