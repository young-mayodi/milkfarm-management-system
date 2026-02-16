class CowsController < ApplicationController
  include PerformanceHelper

  before_action :set_farm, except: [ :index, :show ]
  before_action :set_cow, only: [ :show, :edit, :update, :destroy, :graduate_to_dairy, :mark_as_sold, :mark_as_deceased, :reactivate ]

  def index
    # Build base query with aggressive eager loading to prevent N+1 queries
    @base_query = Cow.includes(:farm, :mother, production_records: [ :farm ])
                     .joins(:farm)
                     .references(:farm)

    # Apply farm filter
    @farm = Farm.find(params[:farm_id]) if params[:farm_id].present?
    @base_query = @base_query.where(farm_id: @farm.id) if @farm

    # Apply search filter using optimized scope
    if params[:search].present?
      @base_query = @base_query.search_by_name_or_tag(params[:search])
    end

    # Apply status filter
    @base_query = @base_query.where(status: params[:status]) if params[:status].present?

    # Apply breed filter
    @base_query = @base_query.where(breed: params[:breed]) if params[:breed].present?

    # Apply animal type filter
    if params[:animal_type].present?
      case params[:animal_type]
      when "adults"
        @base_query = @base_query.adult_cows
      when "calves"
        @base_query = @base_query.calves.includes(:mother)
      end
    end

    # Apply age range filter
    if params[:age_range].present?
      case params[:age_range]
      when "0-2"
        @base_query = @base_query.where("cows.age" => 0..2)
      when "3-5"
        @base_query = @base_query.where("cows.age" => 3..5)
      when "6-8"
        @base_query = @base_query.where("cows.age" => 6..8)
      when "9+"
        @base_query = @base_query.where("cows.age >= ?", 9)
      end
    end

    # Apply sorting
    sort_column = params[:sort] || "name"
    sort_direction = params[:direction] || "asc"

    # Validate sort parameters to prevent SQL injection
    allowed_sorts = %w[name tag_number age status breed]
    sort_column = "name" unless allowed_sorts.include?(sort_column)
    sort_direction = "asc" unless %w[asc desc].include?(sort_direction)

    @base_query = @base_query.order("cows.#{sort_column} #{sort_direction}")

    # Get total count before pagination (for pagination info)
    @total_count = @base_query.count

    # Apply pagination with consistent includes
    per_page = (params[:per_page] || 50).to_i.clamp(25, 250)
    @cows = @base_query.page(params[:page]).per(per_page)

    # Calculate statistics efficiently
    @stats = calculate_cow_stats

    # Load production data efficiently for table display only when needed
    load_production_data_for_table if params[:view] != "cards"

    # Handle different response formats
    respond_to do |format|
      format.html {
        # Ensure no caching for dynamic content
        response.headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
        response.headers["Pragma"] = "no-cache"
        response.headers["Expires"] = "0"

        render params[:view] == "cards" ? :index : :index_scalable
      }
      format.csv { send_csv_export }
      format.pdf { send_pdf_export }
      format.json {
        render json: {
          cows: @cows.as_json(include: :farm),
          total_count: @total_count,
          stats: @stats
        }
      }
    end
  end

  def show
    Rails.logger.info "=== COW SHOW ACTION DEBUG ==="
    Rails.logger.info "Cow ID: #{params[:id]}"
    Rails.logger.info "Cow Name: #{@cow.name}"
    Rails.logger.info "Current User: #{current_user&.email}"

    # Use service for cow performance analytics with caching
    @analytics_service = ProductionAnalyticsService.new
    @cow_performance = @analytics_service.cow_performance_metrics(@cow.id)

    # Optimized recent production with limited fields
    @recent_production = @cow.production_records
      .select(:id, :production_date, :total_production, :morning_production, :noon_production, :evening_production, :night_production)
      .recent
      .limit(10)

    @average_production = @cow.average_daily_production(30)

    # Production statistics - calculated once in controller to avoid N+1
    @records_7_days_count = @cow.production_records.where(production_date: 7.days.ago..Date.current).count
    @last_7_days_avg = @cow.production_records.where(production_date: 7.days.ago..Date.current).average(:total_production)&.to_f || 0
    @prev_7_days_avg = @cow.production_records.where(production_date: 14.days.ago..8.days.ago).average(:total_production)&.to_f || 0
    @production_max = @cow.production_records.maximum(:total_production)&.to_f || 0
    @production_min = @cow.production_records.minimum(:total_production)&.to_f || 0
    @production_total = @cow.production_records.sum(:total_production)&.to_f || 0

    Rails.logger.info "Recent production count: #{@recent_production.count}"
    Rails.logger.info "Average production: #{@average_production}"

    # Chart data for last 30 days production
    daily_production = @cow.production_records
      .where(production_date: 30.days.ago..Date.current)
      .order(:production_date)

    Rails.logger.info "Daily production records: #{daily_production.count}"

    @production_chart_data = {
      labels: daily_production.map { |record| record.production_date.strftime("%m/%d") },
      datasets: [
        {
          label: "Morning (L)",
          data: daily_production.map { |record| record.morning_production.round(1).to_f },
          borderColor: "rgba(255, 159, 64, 1)",
          backgroundColor: "rgba(255, 159, 64, 0.2)",
          tension: 0.4
        },
        {
          label: "Noon (L)",
          data: daily_production.map { |record| record.noon_production.round(1).to_f },
          borderColor: "rgba(54, 162, 235, 1)",
          backgroundColor: "rgba(54, 162, 235, 0.2)",
          tension: 0.4
        },
        {
          label: "Evening (L)",
          data: daily_production.map { |record| record.evening_production.round(1).to_f },
          borderColor: "rgba(153, 102, 255, 1)",
          backgroundColor: "rgba(153, 102, 255, 0.2)",
          tension: 0.4
        },
        {
          label: "Total (L)",
          data: daily_production.map { |record| record.total_production.round(1).to_f },
          borderColor: "rgba(75, 192, 192, 1)",
          backgroundColor: "rgba(75, 192, 192, 0.2)",
          tension: 0.4,
          borderWidth: 3
        }
      ]
    }

    Rails.logger.info "Chart data labels count: #{@production_chart_data[:labels].count}"

    # Weekly production summary - simplified approach
    recent_records = @cow.production_records
      .where(production_date: 4.weeks.ago..Date.current)
      .order(:production_date)

    # Group by week manually
    weekly_data = {}
    recent_records.each do |record|
      week_start = record.production_date.beginning_of_week
      weekly_data[week_start] ||= []
      weekly_data[week_start] << record.total_production
    end

    # Calculate averages
    weekly_averages = weekly_data.transform_values do |productions|
      productions.sum.to_f / productions.count
    end

    @weekly_chart_data = {
      labels: weekly_averages.keys.map { |date| "Week of #{date.strftime('%m/%d')}" },
      datasets: [
        {
          label: "Weekly Average Production (L)",
          data: weekly_averages.values.map { |val| (val&.round(1) || 0).to_f },
          backgroundColor: "rgba(255, 99, 132, 0.8)",
          borderColor: "rgba(255, 99, 132, 1)",
          borderWidth: 2
        }
      ]
    }

    Rails.logger.info "Weekly chart data labels count: #{@weekly_chart_data[:labels].count}"
    Rails.logger.info "=== END COW SHOW ACTION DEBUG ==="
  end

  def new
    @cow = @farm.cows.new
  end

  def create
    @cow = @farm.cows.new(cow_params)

    if @cow.save
      redirect_to [ @farm, @cow ], notice: "Cow was successfully created."
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @cow.update(cow_params)
      redirect_to [ @farm, @cow ], notice: "Cow was successfully updated."
    else
      render :edit
    end
  end

  def destroy
    # Use soft delete to preserve data
    @cow.soft_delete!
    redirect_to farm_cows_url(@farm), notice: "#{@cow.name} has been archived. Data preserved for records."
  end

  # Lifecycle management actions
  def graduate_to_dairy
    if @cow.ready_for_dairy?
      @cow.graduate_to_dairy!
      redirect_back(fallback_location: [ @farm, @cow ],
                    notice: "#{@cow.name} has been graduated to dairy cow status.")
    else
      redirect_back(fallback_location: [ @farm, @cow ],
                    alert: "#{@cow.name} is not ready for dairy graduation.")
    end
  end

  def mark_as_sold
    @cow.mark_as_sold!
    redirect_back(fallback_location: [ @farm, @cow ],
                  notice: "#{@cow.name} has been marked as sold.")
  end

  def mark_as_deceased
    reason = params[:reason] || "Unknown cause"
    @cow.mark_as_deceased!

    # Create death record with reason
    DeathRecord.create!(
      cow: @cow,
      death_date: Date.current,
      cause: reason,
      farm: @cow.farm
    ) rescue nil # Don't fail if DeathRecord doesn't exist yet

    redirect_back(fallback_location: [ @farm, @cow ],
                  notice: "#{@cow.name} has been marked as deceased.")
  end

  def reactivate
    if @cow.status.in?([ "sold", "deceased" ])
      @cow.update!(status: "active")
      redirect_back(fallback_location: [ @farm, @cow ],
                    notice: "#{@cow.name} has been reactivated.")
    else
      redirect_back(fallback_location: [ @farm, @cow ],
                    alert: "Cannot reactivate #{@cow.name} with current status.")
    end
  end

  def search
    query = params[:q].to_s.downcase.strip

    if query.present?
      cows = Cow.where(status: "active")
                .where("LOWER(name) LIKE ? OR LOWER(tag_number) LIKE ?", "%#{query}%", "%#{query}%")
                .joins(:production_records)
                .where(production_records: { production_date: 1.week.ago..Date.current })
                .group("cows.id")
                .select("cows.*, AVG(production_records.total_production) as avg_production")
                .limit(10)
                .order("avg_production DESC")
    else
      cows = []
    end

    render json: {
      cows: cows.map do |cow|
        {
          id: cow.id,
          name: cow.name,
          tag_number: cow.tag_number,
          avg_production: cow.avg_production&.round(1) || 0,
          url: cow_path(cow)
        }
      end
    }
  end

  def chart_data
    respond_to do |format|
      format.json do
        if params[:chart_type] == "calves_growth"
          render json: calves_growth_chart_data
        elsif params[:chart_type] == "calves_weight_distribution"
          render json: calves_weight_distribution_data
        elsif params[:chart_type] == "calves_by_mother"
          render json: calves_by_mother_data
        else
          render json: { error: "Unknown chart type" }, status: :bad_request
        end
      end
    end
  end

  private

  def set_farm
    @farm = Farm.find(params[:farm_id]) if params[:farm_id].present?

    # For standalone cow routes without farm_id, try to get farm from the cow
    if @farm.nil? && params[:id].present?
      cow = Cow.find(params[:id])
      @farm = cow.farm
    end

    # For standalone new/create routes without farm_id, default to first farm if available
    if @farm.nil? && action_name.in?(%w[new create])
      @farm = current_user.farms.first if current_user
      
      if @farm.nil?
        redirect_to farms_path, alert: "Please select a farm first to add a cow." and return
      end
    end

    # SECURITY: Ensure user can only access their own farm's data
    authorize_farm_access! if @farm
  end

  def set_cow
    if @farm
      @cow = @farm.cows.includes(:production_records).find(params[:id])
    else
      @cow = Cow.includes(:production_records).find(params[:id])
    end
  end

  def cow_params
    params.require(:cow).permit(:name, :tag_number, :breed, :age, :group_name, :status, :mother_id, :sire_id,
                                :current_weight, :prev_weight, :weight_gain, :avg_daily_gain, :birth_date)
  end

  # SECURITY: Authorize farm access - users can only access their own farm's data
  def authorize_farm_access!
    return if current_user.nil? # Will be caught by authenticate_user!

    # Farm owners can access all farms
    return if current_user.farm_owner? && current_user.farm.nil?

    # Other users can only access their own farm
    if @farm && current_user.farm_id != @farm.id
      redirect_to dashboard_path, alert: "Access denied. You can only access your own farm's data."
    end
  end

  # Calculate summary statistics efficiently with caching
  def calculate_cow_stats
    # Use cache key based on query parameters to avoid recalculation
    cache_key = "cow_stats_#{@farm&.id}_#{params[:animal_type]}_#{params[:status]}_#{params[:search]}_#{Date.current}"

    Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
      # Get cow IDs from the filtered query to avoid GROUP BY issues
      cow_ids = @base_query.unscope(:order).distinct.pluck(:id)

      if cow_ids.any?
        stats = {}
        stats[:total_count] = cow_ids.count
        stats[:active_count] = @base_query.where(status: "active").distinct.count(:id)

        # Add calves-specific stats when viewing calves
        if params[:animal_type] == "calves"
          stats.merge!(calculate_calves_stats(cow_ids))
        else
          # Optimized stats for adults/all with single query
          recent_production = ProductionRecord.joins(:cow)
            .where(cow_id: cow_ids)
            .where("production_date >= ?", 7.days.ago)

          stats[:avg_daily_production] = recent_production.average(:total_production)&.round(2) || 0
          stats[:total_recent_production] = recent_production.sum(:total_production)&.round(2) || 0
        end

        stats
      else
        default_stats
      end
    end
  end

  # Calves growth chart data
  def calves_growth_chart_data
    farm = @farm || Farm.find(params[:farm_id]) if params[:farm_id]
    calves = farm ? farm.cows.calves : Cow.calves
    calves = calves.where.not(birth_date: nil, current_weight: nil)

    {
      labels: calves.map(&:name),
      datasets: [
        {
          label: "Current Weight (kg)",
          data: calves.map(&:current_weight),
          backgroundColor: "rgba(102, 126, 234, 0.6)",
          borderColor: "rgba(102, 126, 234, 1)",
          borderWidth: 2
        },
        {
          label: "Previous Weight (kg)",
          data: calves.map(&:prev_weight),
          backgroundColor: "rgba(72, 187, 120, 0.6)",
          borderColor: "rgba(72, 187, 120, 1)",
          borderWidth: 2
        }
      ]
    }
  end

  # Calves weight distribution chart data
  def calves_weight_distribution_data
    farm = @farm || Farm.find(params[:farm_id]) if params[:farm_id]
    calves = farm ? farm.cows.calves : Cow.calves
    calves = calves.where.not(current_weight: nil)

    weight_ranges = {
      "0-50kg" => calves.where(current_weight: 0..50).count,
      "51-100kg" => calves.where(current_weight: 51..100).count,
      "101-150kg" => calves.where(current_weight: 101..150).count,
      "151-200kg" => calves.where(current_weight: 151..200).count,
      "200kg+" => calves.where("current_weight > ?", 200).count
    }

    {
      labels: weight_ranges.keys,
      datasets: [ {
        data: weight_ranges.values,
        backgroundColor: [
          "#FF6384",
          "#36A2EB",
          "#FFCE56",
          "#4BC0C0",
          "#9966FF"
        ]
      } ]
    }
  end

  # Calves by mother chart data
  def calves_by_mother_data
    farm = @farm || Farm.find(params[:farm_id]) if params[:farm_id]
    calves = farm ? farm.cows.calves : Cow.calves

    mothers_data = calves.joins(:mother)
                         .group("mothers_cows.name")
                         .count

    {
      labels: mothers_data.keys,
      datasets: [ {
        data: mothers_data.values,
        backgroundColor: [
          "#FF6384",
          "#36A2EB",
          "#FFCE56",
          "#4BC0C0",
          "#9966FF",
          "#FF9F40"
        ]
      } ]
    }
  end

  # Calculate calves-specific statistics
  def calculate_calves_stats(cow_ids)
    calves = Cow.where(id: cow_ids)

    {
      avg_weight: calves.where.not(current_weight: nil).average(:current_weight)&.round(1) || 0,
      total_weight_gain: calves.where.not(weight_gain: nil).sum(:weight_gain)&.round(1) || 0,
      avg_daily_gain: calves.where.not(avg_daily_gain: nil).average(:avg_daily_gain)&.round(3) || 0,
      with_mothers_count: calves.with_mother.count,
      fast_growing_count: calves.where("avg_daily_gain >= ?", 0.7).count,
      birth_this_year: calves.where("birth_date >= ?", Date.current.beginning_of_year).count
    }
  end

  # Default statistics when no cows found
  def default_stats
    {
      total_count: 0,
      active_count: 0,
      avg_daily_production: 0,
      total_recent_production: 0,
      avg_weight: 0,
      total_weight_gain: 0,
      avg_daily_gain: 0,
      with_mothers_count: 0,
      fast_growing_count: 0,
      birth_this_year: 0
    }
  end

  # Load production data for table display (only when needed)
  def load_production_data_for_table
    return if @cows.empty?

    cow_ids = @cows.unscope(:order).distinct.pluck(:id)

    # Get last production record for each cow - optimized query
    @last_productions = ProductionRecord
      .select("DISTINCT ON (cow_id) cow_id, production_date, total_production")
      .where(cow_id: cow_ids)
      .order(:cow_id, production_date: :desc)
      .index_by(&:cow_id)

    # Get 30-day totals for each cow in single query
    @monthly_productions = ProductionRecord
      .where(cow_id: cow_ids, production_date: 30.days.ago..Date.current)
      .group(:cow_id)
      .sum(:total_production)
  end

  # CSV export functionality
  def send_csv_export
    require "csv"

    csv_data = CSV.generate(headers: true) do |csv|
      csv << [ "Name", "Tag Number", "Breed", "Age", "Status", "Farm", "Last Production", "30-Day Total" ]

      @cows.includes(:farm).find_each do |cow|
        last_production = cow.production_records.recent.first&.total_production || 0
        monthly_total = cow.production_records
                          .where(production_date: 30.days.ago..Date.current)
                          .sum(:total_production)

        csv << [
          cow.name,
          cow.tag_number,
          cow.breed || "Unknown",
          cow.age || 0,
          cow.status || "active",
          cow.farm.name,
          last_production.round(1),
          monthly_total.round(1)
        ]
      end
    end

    send_data csv_data,
              filename: "animals_export_#{Date.current.strftime('%Y%m%d')}.csv",
              type: "text/csv",
              disposition: "attachment"
  end

  # PDF export functionality (placeholder)
  def send_pdf_export
    # Implementation for PDF export would go here
    redirect_to cows_path, alert: "PDF export coming soon!"
  end
end
