class ProductionRecordsController < ApplicationController
  before_action :set_farm_and_cow
  before_action :set_production_record, only: [ :show, :edit, :update, :destroy ]

  def index
    # Optimized base query with proper includes
    @production_records = ProductionRecord
      .joins(:cow, :farm)
      .select(
        "production_records.*",
        "cows.name as cow_name",
        "cows.tag_number",
        "farms.name as farm_name"
      )
      .includes(:cow, :farm)

    @production_records = @production_records.where(farm: @farm) if @farm
    @production_records = @production_records.where(cow: @cow) if @cow

    # Date filtering with index optimization
    if params[:start_date].present? && params[:end_date].present?
      @production_records = @production_records.where(production_date: params[:start_date]..params[:end_date])
    end

    @production_records = @production_records.recent.page(params[:page]).per(20)

    # Use optimized analytics service with fallback
    begin
      analytics_service = ProductionAnalyticsService.new(
        farm_id: @farm&.id,
        date_range: 1.week.ago..Date.current
      )

      @analytics_data = analytics_service.dashboard_data
      @top_performers = @analytics_data[:top_performers] || []
      @recent_high_producers = @analytics_data[:recent_high_producers] || []
      @production_summary = @analytics_data[:production_summary] || {}
    rescue NameError => e
      Rails.logger.error "ProductionAnalyticsService not found: #{e.message}"
      # Fallback to basic queries
      @top_performers = []
      @recent_high_producers = []
      @production_summary = {}
    rescue StandardError => e
      Rails.logger.error "Error loading analytics: #{e.message}"
      @top_performers = []
      @recent_high_producers = []
      @production_summary = {}
    end

    respond_to do |format|
      format.html
      format.csv { send_csv_data(@production_records, "production_records") }
      format.json { render json: {
        records: @production_records,
        analytics: @analytics_data
      }}
    end
  end

  def show
  end

  def new
    @production_record = ProductionRecord.new
    @production_record.farm = @farm if @farm
    @production_record.cow = @cow if @cow
    @production_record.production_date = Date.current

    @cows = @farm ? @farm.cows.active : Cow.active
    @farms = Farm.all unless @farm
  end

  def create
    @production_record = ProductionRecord.new(production_record_params)

    if @production_record.save
      redirect_path = if @farm && @cow
                        farm_cow_production_records_path(@farm, @cow)
      elsif @farm
                        farm_production_records_path(@farm)
      else
                        production_records_path
      end
      redirect_to redirect_path, notice: "Production record was successfully created."
    else
      @cows = @farm ? @farm.cows.active : Cow.active
      @farms = Farm.all unless @farm
      render :new
    end
  end

  def edit
    @cows = @farm ? @farm.cows.active : Cow.active
    @farms = Farm.all unless @farm
  end

  def update
    if @production_record.update(production_record_params)
      redirect_path = if @farm && @cow
                        farm_cow_production_records_path(@farm, @cow)
      elsif @farm
                        farm_production_records_path(@farm)
      else
                        production_records_path
      end
      redirect_to redirect_path, notice: "Production record was successfully updated."
    else
      @cows = @farm ? @farm.cows.active : Cow.active
      @farms = Farm.all unless @farm
      render :edit
    end
  end

  def destroy
    @production_record.destroy
    redirect_path = if @farm && @cow
                      farm_cow_production_records_path(@farm, @cow)
    elsif @farm
                      farm_production_records_path(@farm)
    else
                      production_records_path
    end
    redirect_to redirect_path, notice: "Production record was successfully deleted."
  end

  # Bulk/Excel-like entry - Redirect to enhanced version
  def bulk_entry
    redirect_to enhanced_bulk_entry_production_records_path(params.permit(:date, :farm_id, :cow_id))
  end

  # Enhanced bulk entry with improved UX and smart features
  def enhanced_bulk_entry
    @date = params[:date]&.to_date || Date.current
    @farm = Farm.find(params[:farm_id]) if params[:farm_id].present?
    @farm ||= current_farm

    # Check if date is more than 3 days old and user doesn't have admin privileges
    @days_back = (Date.current - @date).to_i
    @can_edit_old_records = can_edit_historical_records?(@date)

    if @days_back > 3 && !@can_edit_old_records
      flash.now[:warning] = "Records older than 3 days can only be edited by farm managers or owners. Please contact your administrator."
      @readonly_mode = true
    else
      @readonly_mode = false
    end

    # Get all animals that can be milked with optimized single query
    @cows = if @farm
              @farm.cows.milkable_animals.includes(:farm).order(:name)
    else
              Cow.milkable_animals.includes(:farm).order(:name)
    end

    # Get existing records for the date with optimized single query
    @existing_records = {}
    if @cows.any?
      cow_ids = @cows.pluck(:id)
      existing_records_array = ProductionRecord
        .where(cow_id: cow_ids, production_date: @date)
        .index_by(&:cow_id)
      @existing_records = existing_records_array
    end

    # Create records for all cows (existing or new) - avoid N+1 queries
    @records = @cows.map do |cow|
      @existing_records[cow.id] || ProductionRecord.new(
        cow: cow,
        farm: @farm,
        production_date: @date,
        morning_production: 0,
        noon_production: 0,
        evening_production: 0
      )
    end

    # Calculate enhanced summary statistics efficiently
    @summary_stats = calculate_bulk_entry_stats(@records, @existing_records)

    # Additional data for enhanced UI - optimized queries
    @previous_day_data = get_previous_day_averages(@farm, @date - 1.day) if @farm
    @farm_average = calculate_farm_daily_average(@farm) if @farm

    render :enhanced_bulk_entry
  end

  def bulk_update
    @date = params[:date]&.to_date || Date.current
    @farm = Farm.find(params[:farm_id]) if params[:farm_id].present?
    @farm ||= current_farm

    # Check edit permissions for historical records
    unless can_edit_historical_records?(@date)
      render json: { error: "You don't have permission to edit records older than 3 days." }, status: :forbidden
      return
    end

    success_count = 0
    error_count = 0
    errors = []
    updated_cows = []
    real_time_updates = []

    params[:records]&.each do |cow_id, record_params|
      # Skip if all production values are blank or zero
      next if all_production_empty?(record_params)

      cow = Cow.find(cow_id)
      record = ProductionRecord.find_or_initialize_by(
        cow: cow,
        production_date: @date
      )

      # Track original values for change detection
      was_new_record = record.new_record?
      original_total = record.total_production || 0

      record.assign_attributes(
        farm: @farm,
        morning_production: sanitize_production_value(record_params[:morning_production]),
        noon_production: sanitize_production_value(record_params[:noon_production]),
        evening_production: sanitize_production_value(record_params[:evening_production])
      )

      if record.save
        success_count += 1
        updated_cows << {
          name: cow.name,
          was_new: was_new_record,
          old_total: original_total,
          new_total: record.total_production
        }

        # Prepare real-time update data
        real_time_updates << {
          cow_id: cow.id,
          cow_name: cow.name,
          morning_production: record.morning_production,
          noon_production: record.noon_production,
          evening_production: record.evening_production,
          total_production: record.total_production,
          updated_at: record.updated_at.iso8601
        }
      else
        error_count += 1
        errors << "#{cow.name}: #{record.errors.full_messages.join(', ')}"
      end
    end

    # Broadcast real-time updates to other browser windows
    if real_time_updates.any?
      broadcast_bulk_entry_updates(@farm&.id, @date, real_time_updates)
    end

    # Handle different response formats
    respond_to do |format|
      format.json do
        if error_count == 0
          render json: {
            success: true,
            message: generate_bulk_update_success_message(success_count, updated_cows),
            updates: real_time_updates,
            stats: { success_count: success_count, error_count: error_count }
          }
        else
          render json: {
            success: false,
            message: "#{success_count} records saved, #{error_count} failed.",
            errors: errors,
            stats: { success_count: success_count, error_count: error_count }
          }
        end
      end

      format.html do
        if error_count == 0
          success_message = generate_bulk_update_success_message(success_count, updated_cows)
          redirect_to bulk_entry_production_records_path(date: @date, farm_id: @farm&.id),
                      notice: success_message
        else
          redirect_to bulk_entry_production_records_path(date: @date, farm_id: @farm&.id),
                      alert: "#{success_count} records saved, #{error_count} failed. Errors: #{errors.join('; ')}"
        end
      end
    end
  end

  # Auto-save draft functionality
  def save_draft
    @date = params[:date]&.to_date || Date.current
    @farm = Farm.find(params[:farm_id]) if params[:farm_id].present?

    begin
      saved_count = 0
      errors = []

      if params[:records].present?
        params[:records].each do |cow_id, record_params|
          cow = Cow.find(cow_id)
          next unless cow

          # Find or create the production record
          production_record = ProductionRecord.find_or_initialize_by(
            cow: cow,
            production_date: @date
          )

          # Update with new values only if they're provided
          production_record.assign_attributes(
            farm: @farm || cow.farm,
            morning_production: record_params[:morning_production].present? ?
              record_params[:morning_production].to_f : production_record.morning_production,
            noon_production: record_params[:noon_production].present? ?
              record_params[:noon_production].to_f : production_record.noon_production,
            evening_production: record_params[:evening_production].present? ?
              record_params[:evening_production].to_f : production_record.evening_production
          )

          # Calculate total
          production_record.calculate_total_production

          if production_record.save
            saved_count += 1
          else
            errors << "Cow #{cow.tag_number}: #{production_record.errors.full_messages.join(', ')}"
          end
        end
      end

      render json: {
        success: true,
        message: "Draft auto-saved: #{saved_count} records",
        saved_count: saved_count,
        errors: errors,
        timestamp: Time.current.strftime("%H:%M:%S")
      }

    rescue StandardError => e
      Rails.logger.error "Auto-save error: #{e.message}"
      render json: {
        success: false,
        message: "Auto-save failed: #{e.message}",
        timestamp: Time.current.strftime("%H:%M:%S")
      }, status: :unprocessable_entity
    end
  end

  # Server-Sent Events endpoint for real-time bulk entry updates
  def bulk_entry_stream
    response.headers["Content-Type"] = "text/event-stream"
    response.headers["Cache-Control"] = "no-cache"
    response.headers["Connection"] = "keep-alive"

    begin
      # Send connection confirmation and close immediately
      response.stream.write("data: {\"type\":\"connected\",\"timestamp\":#{Time.current.to_i}}\n\n")
      response.stream.write("data: {\"type\":\"disconnected\",\"timestamp\":#{Time.current.to_i}}\n\n")
    rescue IOError, StandardError => e
      # Handle any errors gracefully
      logger.error "SSE error: #{e.message}"
    ensure
      response.stream.close
    end
  end

  private

  def set_farm_and_cow
    @farm = Farm.find(params[:farm_id]) if params[:farm_id]
    @cow = @farm ? @farm.cows.find(params[:cow_id]) : Cow.find(params[:cow_id]) if params[:cow_id]
  end

  def set_production_record
    @production_record = ProductionRecord.find(params[:id])
  end

  def production_record_params
    params.require(:production_record).permit(:cow_id, :farm_id, :production_date,
                                              :morning_production, :noon_production, :evening_production)
  end

  # Broadcast real-time updates to other browser windows
  def broadcast_bulk_entry_updates(farm_id, date, updates)
    channel = "bulk_entry_#{farm_id}_#{date.strftime('%Y%m%d')}"

    message = {
      type: "production_update",
      farm_id: farm_id,
      date: date.strftime("%Y-%m-%d"),
      updates: updates,
      timestamp: Time.current.to_i
    }.to_json

    begin
      # Try to use Redis for broadcasting if available
      redis = Redis.new
      redis.publish(channel, message)
    rescue Redis::BaseError => e
      # Redis not available, log the error but don't fail the request
      Rails.logger.warn "Could not broadcast real-time updates: #{e.message}"
      # In production, you might want to use ActionCable or another pub/sub system
    end
  end

  def send_csv_data(records, filename)
    require "csv"

    csv_data = CSV.generate(headers: true) do |csv|
      csv << [ "Date", "Farm", "Cow Name", "Tag Number", "Morning (L)", "Noon (L)", "Evening (L)", "Total (L)" ]

      records.includes(:cow, :farm).each do |record|
        csv << [
          record.production_date.strftime("%Y-%m-%d"),
          record.farm.name,
          record.cow.name,
          record.cow.tag_number,
          record.morning_production,
          record.noon_production,
          record.evening_production,
          record.total_production
        ]
      end
    end

    send_data csv_data,
              filename: "#{filename}_#{Date.current.strftime('%Y%m%d')}.csv",
              type: "text/csv",
              disposition: "attachment"
  end

  # Access control for historical records
  def can_edit_historical_records?(date)
    days_back = (Date.current - date).to_i
    return true if days_back <= 3 # Anyone can edit within 3 days
    return true if current_user.farm_manager? || current_user.farm_owner? # Managers and owners can edit old records
    false
  end

  # Helper method to check if all production values are empty/zero
  def all_production_empty?(record_params)
    morning = sanitize_production_value(record_params[:morning_production])
    noon = sanitize_production_value(record_params[:noon_production])
    evening = sanitize_production_value(record_params[:evening_production])

    morning.zero? && noon.zero? && evening.zero?
  end

  # Sanitize production values to handle empty strings and invalid data
  def sanitize_production_value(value)
    return 0.0 if value.blank?
    value.to_f.round(1).clamp(0.0, 50.0) # Max 50L per session seems reasonable
  end

  # Calculate summary statistics for bulk entry
  def calculate_bulk_entry_stats(records, existing_records)
    total_cows = records.count
    completed_records = existing_records.count { |_, record| record.total_production > 0 }
    completion_percentage = total_cows > 0 ? (completed_records.to_f / total_cows * 100).round(1) : 0

    total_production = existing_records.values.sum(&:total_production)
    average_production = completed_records > 0 ? (total_production / completed_records).round(1) : 0

    {
      total_cows: total_cows,
      completed_records: completed_records,
      completion_percentage: completion_percentage,
      total_production: total_production.round(1),
      average_production: average_production,
      remaining_cows: total_cows - completed_records
    }
  end

  # Generate detailed success message for bulk updates
  def generate_bulk_update_success_message(success_count, updated_cows)
    new_records = updated_cows.count { |cow| cow[:was_new] }
    updated_records = success_count - new_records

    message_parts = []
    message_parts << "✅ Successfully saved #{success_count} production record#{'s' if success_count != 1}"

    if new_records > 0
      message_parts << "#{new_records} new record#{'s' if new_records != 1} created"
    end

    if updated_records > 0
      message_parts << "#{updated_records} existing record#{'s' if updated_records != 1} updated"
    end

    # Add total production info
    total_production = updated_cows.sum { |cow| cow[:new_total] }
    if total_production > 0
      message_parts << "Total production: #{total_production.round(1)}L"
    end

    message_parts.join(" | ")
  end

  # Helper method to get previous day averages for smart suggestions
  def get_previous_day_averages(farm, date)
    return {} unless farm

    previous_records = ProductionRecord.joins(:cow)
                                     .where(cow: farm.cows, production_date: date)
                                     .where("morning_production > 0 OR noon_production > 0 OR evening_production > 0")

    return {} if previous_records.empty?

    {
      morning_avg: previous_records.average(:morning_production)&.round(1) || 0,
      noon_avg: previous_records.average(:noon_production)&.round(1) || 0,
      evening_avg: previous_records.average(:evening_production)&.round(1) || 0,
      total_avg: previous_records.average(:total_production)&.round(1) || 0,
      count: previous_records.count
    }
  end

  # Calculate farm's daily average for benchmarking
  def calculate_farm_daily_average(farm)
    return {} unless farm

    recent_records = ProductionRecord.joins(:cow)
                                   .where(cow: farm.cows)
                                   .where(production_date: 7.days.ago..Date.current)
                                   .where("total_production > 0")

    return {} if recent_records.empty?

    {
      daily_avg: recent_records.average(:total_production)&.round(1) || 0,
      cow_avg: (recent_records.sum(:total_production) / farm.cows.active.count).round(1),
      days_counted: recent_records.group(:production_date).count.keys.count
    }
  end
end
