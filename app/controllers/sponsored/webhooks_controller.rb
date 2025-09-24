# frozen_string_literal: true

module Sponsored
  class WebhooksController < ApplicationController
    requires_plugin 'discourse-sponsored-posts'
    skip_before_action :verify_authenticity_token

    def receive
      provider = params[:provider]
      return render plain: "Invalid provider", status: 400 unless %w[stripe paypal].include?(provider)

      case provider
      when 'stripe'
        handle_stripe_webhook
      when 'paypal'
        handle_paypal_webhook
      end
    rescue => e
      Rails.logger.error "Webhook error: #{e.message}"
      render plain: "Error", status: 500
    end

    private

    def handle_stripe_webhook
      # Stripe webhook verification would go here
      # For now, just acknowledge receipt
      render plain: "ok"
    end

    def handle_paypal_webhook
      # PayPal webhook verification would go here
      # For now, just acknowledge receipt
      render plain: "ok"
    end
  end
end