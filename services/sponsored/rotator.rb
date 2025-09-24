# frozen_string_literal: true

module Sponsored
  class Rotator
    def self.pick_for_stream(sponsored_pool, interval_n:)
      # returns a round-robin enumerator index for client to place after every N
      return [] if sponsored_pool.blank?
      
      sponsored_pool.shuffle # simple fairness; improved RR can persist cursor per user
    end
  end
end


