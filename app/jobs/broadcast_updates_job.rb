class BroadcastUpdatesJob < ApplicationJob
  queue_as :default

  def perform(farm_id, date, real_time_updates)
    # Broadcast updates asynchronously to prevent blocking the request
    broadcast_bulk_entry_updates(farm_id, date, real_time_updates)
  end

  private

  def broadcast_bulk_entry_updates(farm_id, date, updates)
    # Use ActionCable to broadcast updates to connected clients
    channel_name = "production_entry_#{farm_id}_#{date}"
    
    ActionCable.server.broadcast(channel_name, {
      type: 'bulk_update',
      farm_id: farm_id,
      date: date,
      updates: updates,
      timestamp: Time.current.iso8601
    })
  rescue StandardError => e
    # Log the error but don't fail the job
    Rails.logger.error "Failed to broadcast production updates: #{e.message}"
  end
end
