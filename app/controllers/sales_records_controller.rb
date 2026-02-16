class SalesRecordsController < ApplicationController
  include PerformanceHelper

  before_action :set_farm
  before_action :set_sales_record, only: [ :show, :edit, :update, :destroy ]

  def index
    # Use eager loading to prevent N+1 queries
    @sales_records = SalesRecord.includes(:farm)
    @sales_records = @sales_records.where(farm: @farm) if @farm

    # Date filtering
    if params[:start_date].present? && params[:end_date].present?
      @sales_records = @sales_records.where(sale_date: params[:start_date]..params[:end_date])
    end

    @sales_records = @sales_records.recent.page(params[:page]).per(20)

    # Cache summary statistics for 30 minutes
    @summary_stats = Rails.cache.fetch("sales_records_summary_#{@farm&.id || 'all'}_#{params[:start_date]}_#{params[:end_date]}", expires_in: 30.minutes) do
      records = SalesRecord.includes(:farm)
      records = records.where(farm: @farm) if @farm
      records = records.where(sale_date: params[:start_date]..params[:end_date]) if params[:start_date].present? && params[:end_date].present?

      {
        total_records: records.count,
        total_milk_sold: (records.sum(:milk_sold) || 0).round(1),
        total_revenue: (records.sum(:total_sales) || 0).round(0),
        total_cash: (records.sum(:cash_sales) || 0).round(0),
        total_mpesa: (records.sum(:mpesa_sales) || 0).round(0),
        avg_price_per_liter: records.any? ? (records.sum(:total_sales).to_f / [ records.sum(:milk_sold), 1 ].max).round(0) : 0,
        avg_milk_per_sale: records.any? ? (records.sum(:milk_sold) / records.count).round(1) : 0
      }
    end

    respond_to do |format|
      format.html
      format.csv { send_csv_data(@sales_records, "sales_records") }
    end
  end

  def show
  end

  def new
    @sales_record = SalesRecord.new
    @sales_record.farm = @farm if @farm
    @sales_record.sale_date = Date.current

    # Use caching for farms list
    @farms = Rails.cache.fetch("farms_list", expires_in: 1.hour) { Farm.all.to_a } unless @farm
  end

  def create
    @sales_record = SalesRecord.new(sales_record_params)
    # SECURITY: Set farm_id from context, not from user input
    @sales_record.farm = @farm || current_user.farm

    if @sales_record.save
      redirect_path = @farm ? farm_sales_records_path(@farm) : sales_records_path
      redirect_to redirect_path, notice: "Sales record was successfully created."
    else
      @farms = Farm.all unless @farm
      render :new
    end
  end

  def edit
    @farms = Farm.all unless @farm
  end

  def update
    if @sales_record.update(sales_record_params)
      redirect_path = @farm ? farm_sales_records_path(@farm) : sales_records_path
      redirect_to redirect_path, notice: "Sales record was successfully updated."
    else
      @farms = Farm.all unless @farm
      render :edit
    end
  end

  def destroy
    @sales_record.destroy
    redirect_path = @farm ? farm_sales_records_path(@farm) : sales_records_path
    redirect_to redirect_path, notice: "Sales record was successfully deleted."
  end

  private

  def set_farm
    @farm = Farm.find(params[:farm_id]) if params[:farm_id]
  end

  def set_sales_record
    @sales_record = SalesRecord.find(params[:id])
  end

  def sales_record_params
    # SECURITY: farm_id is set from context, not from user input
    params.require(:sales_record).permit(:sale_date, :milk_sold, :cash_sales, :mpesa_sales, :buyer)
  end

  def send_csv_data(records, filename)
    require "csv"

    csv_data = CSV.generate(headers: true) do |csv|
      csv << [ "Date", "Farm", "Buyer", "Milk Sold (L)", "Cash Sales", "M-Pesa Sales", "Total Sales", "Price per Liter" ]

      records.includes(:farm).each do |record|
        csv << [
          record.sale_date.strftime("%Y-%m-%d"),
          record.farm.name,
          record.buyer,
          record.milk_sold,
          record.cash_sales,
          record.mpesa_sales,
          record.total_sales,
          (record.total_sales / record.milk_sold).round(2)
        ]
      end
    end

    send_data csv_data,
              filename: "#{filename}_#{Date.current.strftime('%Y%m%d')}.csv",
              type: "text/csv",
              disposition: "attachment"
  end
end
