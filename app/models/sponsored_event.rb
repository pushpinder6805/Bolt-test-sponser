# frozen_string_literal: true

class SponsoredEvent < ActiveRecord::Base
  self.table_name = 'sponsored_events'
  
  belongs_to :sponsored_post
  
  validates :event_type, presence: true, inclusion: { in: %w[impression click like reply] }
  validates :occurred_at, presence: true

  scope :recent, ->(days = 7) { where("occurred_at >= ?", days.days.ago) }
  scope :by_type, ->(type) { where(event_type: type) }
end