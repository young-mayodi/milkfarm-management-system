class FarmsController < ApplicationController
  before_action :set_farm, only: [ :show, :edit, :update, :destroy ]

  def index
    @farms = Farm.all
    @total_cows = Farm.sum(:cows_count)
    @total_active_cows = Farm.sum(:active_cows_count)
  end

  def show
    @cows = @farm.cows.includes(:production_records)
    @recent_production = @farm.production_records.recent.limit(10).includes(:cow)
    @recent_sales = @farm.sales_records.recent.limit(10)

    # Monthly statistics
    @monthly_production = ProductionRecord.monthly_farm_total(@farm)
    @monthly_sales = SalesRecord.monthly_farm_total(@farm)

    # Chart data for last 30 days
    daily_production = @farm.production_records
      .where(production_date: 30.days.ago..Date.current)
      .group(:production_date)
      .sum(:total_production)

    @production_chart_data = {
      labels: daily_production.keys.map { |date| date.strftime("%m/%d") },
      datasets: [
        {
          label: "Daily Production (L)",
          data: daily_production.values.map { |val| val.round(1).to_f },
          borderColor: "rgba(54, 162, 235, 1)",
          backgroundColor: "rgba(54, 162, 235, 0.2)",
          tension: 0.4,
          fill: true
        }
      ]
    }

    # Top performing cows chart
    top_cows = @farm.cows.active.limit(5)
    cow_production = top_cows.map do |cow|
      production = cow.production_records
        .where(production_date: 30.days.ago..Date.current)
        .sum(:total_production)
      [ cow.name, production.round(1).to_f ]
    end

    @cow_chart_data = {
      labels: cow_production.map(&:first),
      datasets: [
        {
          label: "30-Day Total Production (L)",
          data: cow_production.map(&:last),
          backgroundColor: [
            "rgba(255, 99, 132, 0.8)",
            "rgba(54, 162, 235, 0.8)",
            "rgba(255, 205, 86, 0.8)",
            "rgba(75, 192, 192, 0.8)",
            "rgba(153, 102, 255, 0.8)"
          ],
          borderWidth: 2
        }
      ]
    }
  end

  def new
    @farm = Farm.new
  end

  def create
    @farm = Farm.new(farm_params)

    if @farm.save
      redirect_to @farm, notice: "Farm was successfully created."
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @farm.update(farm_params)
      redirect_to @farm, notice: "Farm was successfully updated."
    else
      render :edit
    end
  end

  def destroy
    @farm.destroy
    redirect_to farms_url, notice: "Farm was successfully deleted."
  end

  private

  def set_farm
    @farm = Farm.find(params[:id])
  end

  def farm_params
    params.require(:farm).permit(:name, :location, :contact_phone, :owner)
  end
end
