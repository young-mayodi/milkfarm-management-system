class VaccinationRecordsController < ApplicationController
  before_action   def set_vaccination_record
    @vaccination_record = VaccinationRecord.includes(:cow).find(params[:id])
  end

  def set_cow
    @cow = Cow.find(params[:cow_id]) if params[:cow_id]
  end

  def vaccination_record_params
    params.require(:vaccination_record).permit(
      :cow_id, :vaccine_name, :vaccination_date, :administered_by,
      :next_due_date, :batch_number, :notes, :cost
    )
  end

  # Helper methods for optimization
  def cache_key_for_vaccination_stats
    [@cow&.id, 'vaccination_stats', VaccinationRecord.maximum(:updated_at)&.to_i].compact.join('_')
  end

  def calculate_up_to_date_animals
    # More efficient database query instead of loading all cows into memory
    Cow.active
       .joins(:vaccination_records)
       .where(vaccination_records: { next_due_date: Date.current.. })
       .distinct
       .count
  enduser!
  before_action :set_vaccination_record, only: [ :show, :edit, :update, :destroy ]
  before_action :set_cow, only: [ :index, :new, :create ]

  def index
    # Optimize query with proper eager loading
    base_query = if @cow
      @cow.vaccination_records
    else
      VaccinationRecord.all
    end

    @vaccination_records = base_query
      .includes(cow: [:farm])
      .order(vaccination_date: :desc)
      .page(params[:page])
      .per(20)

    # Cache vaccination statistics for better performance
    @vaccination_stats = Rails.cache.fetch("vaccination_stats_#{cache_key_for_vaccination_stats}", expires_in: 5.minutes) do
      {
        total_records: base_query.count,
        overdue_vaccinations: VaccinationRecord.overdue.count,
        due_soon: VaccinationRecord.due_soon.count,
        up_to_date_animals: calculate_up_to_date_animals
      }
    end
  end

  def show
    @cow = @vaccination_record.cow
  end

  def new
    @vaccination_record = @cow ? @cow.vaccination_records.build : VaccinationRecord.new
    @vaccination_record.vaccination_date = Date.current
    @vaccination_record.administered_by = current_user.name
    @cows = current_farm.cows.active.order(:name) unless @cow
  end

  def create
    @vaccination_record = VaccinationRecord.new(vaccination_record_params)

    if @vaccination_record.save
      redirect_to @vaccination_record, notice: "Vaccination record was successfully created."
    else
      @cows = current_farm.cows.active.order(:name) unless @cow
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @cow = @vaccination_record.cow
    @cows = Cow.active.order(:name)
  end

  def update
    if @vaccination_record.update(vaccination_record_params)
      redirect_to @vaccination_record, notice: "Vaccination record was successfully updated."
    else
      @cow = @vaccination_record.cow
      @cows = Cow.active.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    cow = @vaccination_record.cow
    @vaccination_record.destroy!
    redirect_to cow_vaccination_records_path(cow), notice: "Vaccination record was successfully deleted."
  end

  private

  def set_vaccination_record
    @vaccination_record = VaccinationRecord.find(params[:id])
  end

  def set_cow
    @cow = Cow.find(params[:cow_id]) if params[:cow_id]
  end

  def vaccination_record_params
    params.require(:vaccination_record).permit(
      :cow_id, :vaccine_name, :vaccination_date, :next_due_date,
      :administered_by, :batch_number, :notes, :veterinarian
    )
  end
end
