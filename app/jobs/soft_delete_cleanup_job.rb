class SoftDeleteCleanupJob < ApplicationJob
  queue_as :low_priority

  # Run this job to permanently delete soft-deleted records after 30 days
  def perform
    cutoff_date = 30.days.ago

    # Find and permanently delete cows soft-deleted more than 30 days ago
    deleted_cows = Cow.deleted.where("deleted_at < ?", cutoff_date)

    deleted_cows.find_each do |cow|
      Rails.logger.info("Permanently deleting cow #{cow.id} (#{cow.tag_number}) - deleted on #{cow.deleted_at}")

      # Hard delete - this will cascade to production records if configured
      cow.destroy
    end

    Rails.logger.info("Soft delete cleanup complete - #{deleted_cows.count} cows permanently deleted")
  end
end
