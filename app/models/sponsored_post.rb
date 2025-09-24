# frozen_string_literal: true

class SponsoredPost < ActiveRecord::Base
  self.table_name = 'sponsored_posts'
  
  belongs_to :post
  belongs_to :user
  has_many :sponsored_events, dependent: :destroy

  validates :starts_at, :expires_at, presence: true
  validates :provider, inclusion: { in: %w[stripe paypal] }, allow_blank: true
  validates :impressions, :clicks, :likes, :replies, numericality: { greater_than_or_equal_to: 0 }

  scope :active_now, -> { where(active: true).where("starts_at <= ? AND expires_at > ?", Time.zone.now, Time.zone.now) }
  scope :expired, -> { where("expires_at <= ?", Time.zone.now) }
  scope :pending_approval, -> { where(active: false) }

  def ctr
    return 0.0 if impressions.to_i.zero?
    (clicks.to_f / impressions.to_f * 100).round(2)
  end

  def active?
    active && starts_at <= Time.zone.now && expires_at > Time.zone.now
  end

  def expired?
    expires_at <= Time.zone.now
  end

  def days_remaining
    return 0 if expired?
    ((expires_at - Time.zone.now) / 1.day).ceil
  end
end