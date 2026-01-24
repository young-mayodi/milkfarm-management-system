class VaccinationRecordsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_vaccination_record, only: [ :show, :edit, :update, :destroy ]
  before_action :set_cow, only: [ :index, :new, :create ]

  def index
    @vaccination_records = if @cow
      @cow.vaccination_records.includes(:cow).order(vaccination_date: :desc)
    else
      VaccinationRecord.includes(:cow).order(vaccination_date: :desc)
    end

    @vaccination_records = @vaccination_records.page(params[:page]).per(20)

    # Vaccination statistics
    @vaccination_stats = {
      total_records: @vaccination_records.count,
      overdue_vaccinations: VaccinationRecord.overdue.count,
      due_soon: VaccinationRecord.due_soon.count,
      up_to_date_animals: Cow.active.select { |c| c.vaccination_status == "up_to_date" }.count
    }
  end

  def show
    @cow = @vaccination_record.cow
  end

  def new
    @vaccination_record = @cow ? @cow.vaccination_records.build : VaccinationRecord.new
    @vaccination_record.vaccination_date = Date.current
    @vaccination_record.administered_by = current_user.name
    @cows = Cow.active.order(:name) unless @cow
  end

  def create
    @vaccination_record = VaccinationRecord.new(vaccination_record_params)

    if @vaccination_record.save
      redirect_to @vaccination_record, notice: "Vaccination record was successfully created."
    else
      @cows = Cow.active.order(:name) unless @cow
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
