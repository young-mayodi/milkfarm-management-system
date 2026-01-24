class BreedingRecordsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_breeding_record, only: [ :show, :edit, :update, :destroy ]
  before_action :set_cow, only: [ :index, :new, :create ]

  def index
    @breeding_records = if @cow
      @cow.breeding_records.includes(:cow).order(breeding_date: :desc)
    else
      BreedingRecord.includes(:cow).order(breeding_date: :desc)
    end

    # Breeding statistics (calculate before pagination)
    @breeding_stats = {
      total_records: @breeding_records.count,
      pregnant_animals: BreedingRecord.confirmed.joins(:cow).merge(Cow.active).count,
      due_soon: BreedingRecord.due_soon.count,
      overdue: BreedingRecord.overdue.count
    }

    @breeding_records = @breeding_records.page(params[:page]).per(20)
  end

  def show
    @cow = @breeding_record.cow
  end

  def new
    @breeding_record = @cow ? @cow.breeding_records.build : BreedingRecord.new
    @breeding_record.breeding_date = Date.current
    @cows = current_farm.cows.active.adult_cows.order(:name) unless @cow
  end

  def create
    @breeding_record = BreedingRecord.new(breeding_record_params)

    if @breeding_record.save
      redirect_to @breeding_record, notice: "Breeding record was successfully created."
    else
      @cows = current_farm.cows.active.adult_cows.order(:name) unless @cow
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @cow = @breeding_record.cow
    @cows = Cow.active.adult_cows.order(:name)
  end

  def update
    if @breeding_record.update(breeding_record_params)
      redirect_to @breeding_record, notice: "Breeding record was successfully updated."
    else
      @cow = @breeding_record.cow
      @cows = Cow.active.adult_cows.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    cow = @breeding_record.cow
    @breeding_record.destroy!
    redirect_to cow_breeding_records_path(cow), notice: "Breeding record was successfully deleted."
  end

  private

  def set_breeding_record
    @breeding_record = BreedingRecord.find(params[:id])
  end

  def set_cow
    @cow = Cow.find(params[:cow_id]) if params[:cow_id]
  end

  def breeding_record_params
    params.require(:breeding_record).permit(
      :cow_id, :breeding_date, :bull_name, :breeding_method,
      :expected_due_date, :actual_due_date, :breeding_status,
      :notes, :veterinarian
    )
  end
end
