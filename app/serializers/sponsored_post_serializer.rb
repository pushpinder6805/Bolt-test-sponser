# frozen_string_literal: true

class SponsoredPostSerializer < ApplicationSerializer
  attributes :id, :post_id, :starts_at, :expires_at, :active,
             :impressions, :clicks, :likes, :replies, :ctr,
             :provider, :days_remaining, :expired

  has_one :user, serializer: BasicUserSerializer
  has_one :post, serializer: BasicPostSerializer

  def ctr
    object.ctr
  end

  def days_remaining
    object.days_remaining
  end

  def expired
    object.expired?
  end
end