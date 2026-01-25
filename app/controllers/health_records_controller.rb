class HealthRecordsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_health_record, only: [ :show, :edit, :update, :destroy ]
  before_action :set_cow, only: [ :index, :new, :create ]

  def index
    # Optimize query with proper eager loading and indexing
    base_query = if @cow
      @cow.health_records
    else
      HealthRecord.all
    end

    @health_records = base_query
      .includes(cow: [ :farm ])  # Include farm relation for better optimization
      .order(recorded_at: :desc)
      .page(params[:page])
      .per(20)

    # Optimize health statistics with efficient queries
    @health_stats = Rails.cache.fetch("health_stats_#{cache_key_for_stats}", expires_in: 5.minutes) do
      {
        total_records: base_query.count,
        sick_animals: HealthRecord.sick_animals.joins(:cow).merge(Cow.active).count,
        animals_needing_attention: calculate_animals_needing_attention,
        recent_checkups: HealthRecord.recent.count
      }
    end
  end

  def show
    @cow = @health_record.cow
  end

  def new
    @health_record = @cow ? @cow.health_records.build : HealthRecord.new
    @health_record.recorded_at = Time.current
    @health_record.recorded_by = current_user.name
    @cows = current_farm.cows.active.order(:name) unless @cow
  end

  def create
    @health_record = HealthRecord.new(health_record_params)
    @health_record.recorded_at = Time.current if @health_record.recorded_at.blank?

    if @health_record.save
      redirect_to @health_record, notice: "Health record was successfully created."
    else
      @cows = current_farm.cows.active.order(:name) unless @cow
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @cow = @health_record.cow
    @cows = Cow.active.order(:name)
  end

  def update
    if @health_record.update(health_record_params)
      redirect_to @health_record, notice: "Health record was successfully updated."
    else
      @cow = @health_record.cow
      @cows = Cow.active.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    cow = @health_record.cow
    @health_record.destroy!
    redirect_to cow_health_records_path(cow), notice: "Health record was successfully deleted."
  end

  private

  def set_health_record
    @health_record = HealthRecord.includes(:cow).find(params[:id])
  end

  def set_cow
    @cow = Cow.find(params[:cow_id]) if params[:cow_id]
  end

  def health_record_params
    params.require(:health_record).permit(
      :cow_id, :health_status, :temperature, :weight, :notes,
      :recorded_by, :recorded_at, :veterinarian
    )
  end

  # Helper methods for optimization
  def cache_key_for_stats
    [ @cow&.id, "health_stats", HealthRecord.maximum(:updated_at)&.to_i ].compact.join("_")
  end

  def calculate_animals_needing_attention
    # More efficient query instead of loading all cows into memory
    Cow.active
       .joins(:health_records)
       .where(health_records: { health_status: [ "sick", "injured", "critical", "quarantine" ] })
       .distinct
       .count
  end
end
