class HealthRecordsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_health_record, only: [ :show, :edit, :update, :destroy ]
  before_action :set_cow, only: [ :index, :new, :create ]

  def index
    @health_records = if @cow
      @cow.health_records.includes(:cow).order(recorded_at: :desc)
    else
      HealthRecord.includes(:cow).order(recorded_at: :desc)
    end

    @health_records = @health_records.page(params[:page]).per(20)

    # Health statistics
    @health_stats = {
      total_records: @health_records.count,
      sick_animals: HealthRecord.sick_animals.joins(:cow).merge(Cow.active).count,
      animals_needing_attention: Cow.active.select(&:requires_health_attention?).count,
      recent_checkups: HealthRecord.recent.count
    }
  end

  def show
    @cow = @health_record.cow
  end

  def new
    @health_record = @cow ? @cow.health_records.build : HealthRecord.new
    @health_record.recorded_at = Time.current
    @health_record.recorded_by = current_user.name
    @cows = Cow.active.order(:name) unless @cow
  end

  def create
    @health_record = HealthRecord.new(health_record_params)
    @health_record.recorded_at = Time.current if @health_record.recorded_at.blank?

    if @health_record.save
      redirect_to @health_record, notice: "Health record was successfully created."
    else
      @cows = Cow.active.order(:name) unless @cow
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
    @health_record = HealthRecord.find(params[:id])
  end

  def set_cow
    @cow = Cow.find(params[:cow_id]) if params[:cow_id]
  end

  def health_record_params
    params.require(:health_record).permit(
      :cow_id, :health_status, :temperature, :weight, :notes,
      :recorded_by, :recorded_at, :veterinarian, :symptoms, :treatment
    )
  end
end
