# frozen_string_literal: true

module Sponsored
  class StatService
    VALID_EVENTS = %w[impression click like reply].freeze

    def self.bump(sponsored_post, event_type)
      return unless sponsored_post && VALID_EVENTS.include?(event_type.to_s)
      return unless sponsored_post.active?
      
      begin
        # Update counter
        sponsored_post.increment!(event_type.pluralize)
        
        # Create event record
        SponsoredEvent.create!(
          sponsored_post: sponsored_post,
          event_type: event_type,
          occurred_at: Time.zone.now
        )
        
        Rails.logger.info "Sponsored post #{sponsored_post.id} #{event_type} tracked"
      rescue => e
        Rails.logger.error "Failed to bump sponsored post stat: #{e.message}"
      end
    end

    def self.get_stats(sponsored_post, days = 7)
      return {} unless sponsored_post

      events = sponsored_post.sponsored_events.recent(days)
      
      {
        impressions: events.by_type('impression').count,
        clicks: events.by_type('click').count,
        likes: events.by_type('like').count,
        replies: events.by_type('reply').count,
        ctr: calculate_ctr(events),
        period_days: days
      }
    end

    private

    def self.calculate_ctr(events)
      impressions = events.by_type('impression').count
      clicks = events.by_type('click').count
      
      return 0.0 if impressions.zero?
      (clicks.to_f / impressions.to_f * 100).round(2)
    end
  end
end