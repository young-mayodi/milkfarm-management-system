class CalvesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_calf, only: [ :show, :edit, :update, :destroy ]
  before_action :load_farms, only: [ :new, :edit, :create, :update ]

  def index
    @calves = Cow.calves.includes(:farm, :mother)

    # Apply filters
    @calves = @calves.where(farm: current_user.accessible_farms) unless current_user.farm_owner?
    @calves = @calves.where(farm_id: params[:farm_id]) if params[:farm_id].present?
    @calves = @calves.where("cows.status = ?", params[:status]) if params[:status].present?
    @calves = @calves.where("cows.name ILIKE ?", "%#{params[:search]}%") if params[:search].present?

    # For analytics, we don't need production_records since we use database columns
    # Only include production_records for the show page or when specifically needed
    @calves_with_production = @calves.includes(:production_records) if params[:with_production] == "true"

    # Pagination and ordering
    @calves = @calves.order("cows.name").page(params[:page]).per(20)

    # Calculate statistics
    calculate_calf_stats

    # Chart data for calf analytics
    prepare_calf_analytics if @calves.any?

    respond_to do |format|
      format.html
      format.json { render json: @calves.as_json(include: [ :farm, :mother ]) }
      format.csv {
        headers["Content-Disposition"] = "attachment; filename=\"calves_report_#{Date.current}.csv\""
        headers["Content-Type"] = "text/csv"
        render plain: generate_calves_csv
      }
    end
  end

  def show
    @calf = @calf
    @production_records = @calf.production_records.includes(:farm)
                                .order(production_date: :desc)
                                .limit(10)

    # Calf-specific analytics
    prepare_individual_calf_analytics
  end

  def new
    @calf = Cow.new
    @calf.farm = current_user.farm unless current_user.farm_owner?

    # Load potential mothers (adult female cows)
    @potential_mothers = Cow.adult_cows
                            .where(farm: current_user.accessible_farms)
                            .where(status: [ "active", "pregnant" ])
                            .order(:name)
  end

  def create
    @calf = Cow.new(calf_params)

    # Set default birth date if not provided
    @calf.birth_date ||= Date.current if @calf.age && @calf.age < 2

    if @calf.save
      redirect_to calves_path, notice: "Calf was successfully created."
    else
      @potential_mothers = load_potential_mothers
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @potential_mothers = load_potential_mothers
  end

  def update
    if @calf.update(calf_params)
      redirect_to calf_path(@calf), notice: "Calf was successfully updated."
    else
      @potential_mothers = load_potential_mothers
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @calf.destroy
    redirect_to calves_path, notice: "Calf was successfully deleted."
  end

  # API endpoint for calf growth analytics
  def chart_data
    calves = Cow.calves.includes(:production_records)

    growth_data = calves.map do |calf|
      {
        id: calf.id,
        name: calf.name,
        age: calf.age,
        current_weight: calf.current_weight || 0,
        weight_gain: calf.weight_gain || 0,
        avg_daily_gain: calf.avg_daily_gain || 0
      }
    end

    render json: {
      growth_chart: prepare_growth_chart(growth_data),
      age_distribution: prepare_age_distribution(calves),
      health_status: prepare_health_status(calves)
    }
  end

  private

  def set_calf
    @calf = Cow.calves.includes(mother: :calves).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to calves_path, alert: "Calf not found."
  end

  def calf_params
    params.require(:cow).permit(:name, :tag_number, :breed, :age, :farm_id, :group_name,
                                :status, :mother_id, :birth_date, :current_weight,
                                :prev_weight, :weight_gain, :avg_daily_gain)
  end

  def load_farms
    @farms = current_user.farm_owner? ? Farm.all : current_user.accessible_farms
  end

  def load_potential_mothers
    Cow.adult_cows
       .where(farm: current_user.accessible_farms)
       .where(status: [ "active", "pregnant" ])
       .where.not(id: @calf&.id) # Exclude self
       .order(:name)
  end

  def calculate_calf_stats
    all_calves = Cow.calves.where(farm: current_user.accessible_farms)

    @calf_stats = {
      total_calves: all_calves.count,
      healthy_calves: all_calves.where(status: "active").count,
      sick_calves: all_calves.where(status: "sick").count,
      average_age: all_calves.average(:age)&.round(1) || 0,
      average_weight: all_calves.where.not(current_weight: nil).average(:current_weight)&.round(1) || 0,
      with_mothers: all_calves.where.not(mother_id: nil).count,
      orphaned: all_calves.where(mother_id: nil).count
    }

    @growth_stats = {
      total_weight_gain: all_calves.where.not(weight_gain: nil).sum(:weight_gain)&.round(1) || 0,
      average_daily_gain: all_calves.where.not(avg_daily_gain: nil).average(:avg_daily_gain)&.round(2) || 0,
      best_performers: all_calves.where.not(avg_daily_gain: nil)
                                 .order(avg_daily_gain: :desc)
                                 .limit(3)
    }
  end

  def prepare_calf_analytics
    # Age distribution chart data - use pluck to avoid GROUP BY issues
    age_counts = @calves.pluck("cows.age").compact.group_by(&:itself).transform_values(&:count)
    @age_distribution = age_counts

    # Growth progress chart - use pluck to avoid N+1 queries
    @growth_data = @calves.where.not(current_weight: nil)
                          .pluck("cows.name", "cows.weight_gain", "cows.avg_daily_gain", "cows.current_weight")
                          .map { |name, weight_gain, daily_gain, current_weight|
                            {
                              name: name,
                              weight_gain: weight_gain || 0,
                              daily_gain: daily_gain || 0,
                              current_weight: current_weight || 0
                            }
                          }

    # Health status distribution - use pluck to avoid GROUP BY issues
    status_counts = @calves.pluck("cows.status").compact.group_by(&:itself).transform_values(&:count)
    @health_status = status_counts
  end

  def prepare_individual_calf_analytics
    # Individual calf growth tracking
    @growth_timeline = []

    if @calf.prev_weight && @calf.current_weight
      @growth_timeline = [
        { date: 1.month.ago, weight: @calf.prev_weight },
        { date: Date.current, weight: @calf.current_weight }
      ]
    end

    # Milk production for calves that have started producing
    if @calf.production_records.any?
      @production_chart = @calf.production_records
                               .order(:production_date)
                               .limit(30)
                               .pluck(:production_date, :total_production)
    end
  end

  def prepare_growth_chart(growth_data)
    {
      labels: growth_data.map { |d| d[:name] },
      datasets: [ {
        label: "Weight Gain (kg)",
        data: growth_data.map { |d| d[:weight_gain] },
        backgroundColor: "rgba(54, 162, 235, 0.8)"
      }, {
        label: "Daily Gain (kg/day)",
        data: growth_data.map { |d| d[:avg_daily_gain] },
        backgroundColor: "rgba(255, 99, 132, 0.8)",
        type: "line",
        yAxisID: "y1"
      } ]
    }
  end

  def prepare_age_distribution(calves)
    # Manually group ages to avoid SQL GROUP BY issues
    age_data = calves.pluck("cows.age").compact
    age_groups = age_data.group_by do |age|
      case age.to_f
      when 0...6
        "0-6 months"
      when 6...12
        "6-12 months"
      when 12...24
        "12-24 months"
      else
        "24+ months"
      end
    end.transform_values(&:count)

    {
      labels: age_groups.keys,
      datasets: [ {
        data: age_groups.values,
        backgroundColor: [
          "rgba(255, 99, 132, 0.8)",
          "rgba(54, 162, 235, 0.8)",
          "rgba(255, 205, 86, 0.8)",
          "rgba(75, 192, 192, 0.8)"
        ]
      } ]
    }
  end

  def prepare_health_status(calves)
    status_data = calves.pluck("cows.status").compact
    status_counts = status_data.group_by(&:itself).transform_values(&:count)

    {
      labels: status_counts.keys,
      datasets: [ {
        data: status_counts.values,
        backgroundColor: [
          "rgba(75, 192, 192, 0.8)",  # active - green
          "rgba(255, 99, 132, 0.8)",  # sick - red
          "rgba(255, 205, 86, 0.8)",  # inactive - yellow
          "rgba(153, 102, 255, 0.8)"  # pregnant - purple
        ]
      } ]
    }
  end

  def generate_calves_csv
    require "csv"

    CSV.generate(headers: true) do |csv|
      # Add header row
      csv << [
        "Name", "Tag Number", "Age (months)", "Breed", "Farm",
        "Mother", "Status", "Current Weight (kg)", "Weight Gain (kg)",
        "Avg Daily Gain (kg/day)", "Birth Date", "Group"
      ]

      # Add data rows
      @calves.includes(:farm, :mother).find_each do |calf|
        csv << [
          calf.name,
          calf.tag_number,
          calf.age,
          calf.breed,
          calf.farm&.name,
          calf.mother&.name,
          calf.status&.humanize,
          calf.current_weight,
          calf.weight_gain,
          calf.avg_daily_gain,
          calf.birth_date&.strftime("%Y-%m-%d"),
          calf.group_name
        ]
      end
    end
  end
end
