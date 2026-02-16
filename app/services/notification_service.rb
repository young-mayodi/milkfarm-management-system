# frozen_string_literal: true

# Service for managing notifications and email alerts
# Handles creation, delivery, and tracking of user notifications
class NotificationService < ApplicationService
  attr_reader :user, :farm

  def initialize(user: nil, farm: nil)
    @user = user
    @farm = farm
  end

  # Create notification for user
  def create_notification(type:, title:, message:, data: {}, priority: "normal")
    return unless user

    notification = user.notifications.create!(
      notification_type: type,
      title: title,
      message: message,
      data: data,
      priority: priority,
      read: false
    )

    # Send email for high-priority notifications
    send_email_notification(notification) if priority == "high" && user.email_notifications_enabled?

    log_info("Created #{priority} notification for user ##{user.id}: #{title}")
    notification
  rescue => e
    log_error("Failed to create notification: #{e.message}", e)
    nil
  end

  # Create notifications from alerts
  def create_from_alerts(alerts)
    return unless user

    alerts.each do |alert|
      create_notification(
        type: alert[:type],
        title: alert[:title],
        message: alert[:message],
        data: alert[:data],
        priority: alert[:severity] == "critical" ? "high" : "normal"
      )
    end
  end

  # Get unread notifications for user
  def unread_notifications
    return [] unless user

    cache_fetch("unread:#{user.id}", expires_in: 5.minutes) do
      user.notifications.unread.order(created_at: :desc).limit(10)
    end
  end

  # Mark notification as read
  def mark_as_read(notification_id)
    return unless user

    notification = user.notifications.find_by(id: notification_id)
    return unless notification

    notification.update(read: true, read_at: Time.current)
    Rails.cache.delete("#{self.class.name}:unread:#{user.id}")

    log_info("Marked notification ##{notification_id} as read")
    notification
  end

  # Mark all notifications as read
  def mark_all_as_read
    return unless user

    user.notifications.unread.update_all(read: true, read_at: Time.current)
    Rails.cache.delete("#{self.class.name}:unread:#{user.id}")

    log_info("Marked all notifications as read for user ##{user.id}")
  end

  # Send daily summary email
  def send_daily_summary
    return unless user&.email_notifications_enabled?

    alerts = AlertEngineService.call(farm: farm) if farm
    return if alerts.blank?

    # Group alerts by severity
    critical = alerts.select { |a| a[:severity] == "critical" }
    warnings = alerts.select { |a| a[:severity] == "warning" }
    info = alerts.select { |a| a[:severity] == "info" }

    # Send email with summary
    NotificationMailer.daily_summary(
      user: user,
      critical: critical,
      warnings: warnings,
      info: info,
      farm: farm
    ).deliver_later

    log_info("Sent daily summary email to user ##{user.id}")
  rescue => e
    log_error("Failed to send daily summary: #{e.message}", e)
  end

  # Clean up old notifications (keep last 90 days)
  def self.cleanup_old_notifications
    cutoff_date = 90.days.ago
    deleted_count = Notification.where("created_at < ?", cutoff_date).delete_all

    Rails.logger.info("[#{name}] Deleted #{deleted_count} old notifications")
    deleted_count
  end

  private

  def send_email_notification(notification)
    return unless user.email.present?

    NotificationMailer.alert_notification(
      user: user,
      notification: notification,
      farm: farm
    ).deliver_later

    log_info("Queued email for notification ##{notification.id}")
  rescue => e
    log_error("Failed to queue email: #{e.message}", e)
  end
end
