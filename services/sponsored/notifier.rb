# frozen_string_literal: true

module Sponsored
  class Notifier
    def self.notify_admins(sponsored_post)
      return unless sponsored_post&.user&.username && sponsored_post&.post
      
      group_names = SiteSetting.sponsored_notify_admin_group_names.split("|").reject(&:blank?)
      return if group_names.empty?
      
      group_names.each do |group_name|
        group = Group.find_by(name: group_name.strip)
        next unless group
        
        group.users.each do |admin_user|
          begin
            SystemMessage.create_from_system_user(
              admin_user,
              :sponsored_post_submitted,
              username: sponsored_post.user.username,
              post_id: sponsored_post.post_id,
              post_url: "#{Discourse.base_url}/p/#{sponsored_post.post_id}"
            )
          rescue => e
            Rails.logger.error "Failed to send sponsored post notification to #{admin_user.username}: #{e.message}"
          end
        end
      end
      
      send_email_notification(sponsored_post) if SiteSetting.sponsored_notify_email_enabled
    end

    def self.notify_user_approved(sponsored_post)
      return unless sponsored_post&.user

      begin
        SystemMessage.create_from_system_user(
          sponsored_post.user,
          :sponsored_post_approved,
          post_id: sponsored_post.post_id,
          post_url: "#{Discourse.base_url}/p/#{sponsored_post.post_id}"
        )
      rescue => e
        Rails.logger.error "Failed to send approval notification: #{e.message}"
      end
    end

    def self.notify_user_rejected(sponsored_post)
      return unless sponsored_post&.user

      begin
        SystemMessage.create_from_system_user(
          sponsored_post.user,
          :sponsored_post_rejected,
          post_id: sponsored_post.post_id,
          post_url: "#{Discourse.base_url}/p/#{sponsored_post.post_id}"
        )
      rescue => e
        Rails.logger.error "Failed to send rejection notification: #{e.message}"
      end
    end

    private

    def self.send_email_notification(sponsored_post)
      return unless SiteSetting.sponsored_support_email.present?
      
      begin
        Email::Sender.new(
          SponsoredPostMailer.new_sponsored_post(sponsored_post),
          :sponsored_post_notification
        ).send
      rescue => e
        Rails.logger.error "Failed to send sponsored post email: #{e.message}"
      end
    end
  end
end