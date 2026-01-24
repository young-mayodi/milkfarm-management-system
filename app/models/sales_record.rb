class SalesRecord < ApplicationRecord
  # Associations
  belongs_to :farm

  # Validations
  validates :sale_date, presence: true
  validates :milk_sold, presence: true, numericality: { greater_than: 0 }
  validates :cash_sales, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :mpesa_sales, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :buyer, presence: true

  # Callbacks
  before_save :calculate_total_sales

  # Scopes
  scope :for_date, ->(date) { where(sale_date: date) }
  scope :for_month, ->(month, year) {
    where(sale_date: Date.new(year, month, 1)..Date.new(year, month, -1))
  }
  scope :recent, -> { order(sale_date: :desc) }

  # Class methods
  def self.daily_farm_total(farm, date)
    where(farm: farm, sale_date: date).sum(:total_sales)
  end

  def self.monthly_farm_total(farm, month = Date.current.month, year = Date.current.year)
    where(farm: farm)
      .where(sale_date: Date.new(year, month, 1)..Date.new(year, month, -1))
      .sum(:total_sales)
  end

  # Profit/Loss analysis methods
  def self.profit_loss_analysis(farm, date_range = 1.month.ago..Date.current)
    # Get sales data
    sales = where(farm: farm, sale_date: date_range)
    total_revenue = sales.sum(:total_sales)
    total_milk_sold = sales.sum(:milk_sold)

    # Get production data for the same period
    production_records = ProductionRecord.where(farm: farm, production_date: date_range)
    total_production = production_records.sum(:total_production)

    # Calculate estimated costs (these should ideally come from a separate costs table)
    estimated_feed_cost_per_liter = 25.0 # KES per liter (adjust based on actual costs)
    estimated_labor_cost_per_day = 500.0 # KES per day
    estimated_other_costs_per_liter = 5.0 # Vet, maintenance, etc.

    days_in_range = (date_range.end - date_range.begin).to_i + 1
    total_estimated_costs = (total_production * estimated_feed_cost_per_liter) +
                           (days_in_range * estimated_labor_cost_per_day) +
                           (total_production * estimated_other_costs_per_liter)

    gross_profit = total_revenue - total_estimated_costs
    profit_margin = total_revenue > 0 ? (gross_profit / total_revenue * 100) : 0

    # Calculate efficiency metrics
    milk_sold_percentage = total_production > 0 ? (total_milk_sold / total_production * 100) : 0
    average_price_per_liter = total_milk_sold > 0 ? (total_revenue / total_milk_sold) : 0

    {
      period: date_range,
      total_revenue: total_revenue.round(2),
      total_costs: total_estimated_costs.round(2),
      gross_profit: gross_profit.round(2),
      profit_margin: profit_margin.round(2),
      total_production: total_production.round(2),
      total_milk_sold: total_milk_sold.round(2),
      milk_sold_percentage: milk_sold_percentage.round(2),
      average_price_per_liter: average_price_per_liter.round(2),
      break_even_production: total_estimated_costs / (average_price_per_liter > 0 ? average_price_per_liter : 50),
      performance_status: gross_profit > 0 ? "profitable" : "loss"
    }
  end

  def self.monthly_profit_trend(farm, months_back: 6)
    trend_data = {}

    (0..months_back-1).each do |month_offset|
      date = month_offset.months.ago
      month_start = date.beginning_of_month
      month_end = date.end_of_month

      analysis = profit_loss_analysis(farm, month_start..month_end)
      trend_data[month_start] = analysis
      end

    trend_data
  end

  def self.cost_breakdown_analysis(farm, date_range = 1.month.ago..Date.current)
    production_volume = ProductionRecord.where(farm: farm, production_date: date_range).sum(:total_production) || 0
    production_volume = production_volume.to_f

    # Simple fixed cost calculation
    feed_costs = production_volume * 25.0
    labor_costs = 30 * 500.0  # 30 days * 500 per day
    veterinary_costs = production_volume * 3.0
    maintenance_costs = production_volume * 2.0

    # Cost estimates (should be made configurable)
    {
      feed_costs: feed_costs.round(2),
      labor_costs: labor_costs.round(2),
      veterinary_costs: veterinary_costs.round(2),
      maintenance_costs: maintenance_costs.round(2),
      total_estimated_costs: (feed_costs + labor_costs + veterinary_costs + maintenance_costs).round(2)
    }
  end

  private

  def calculate_total_sales
    self.total_sales = (cash_sales || 0) + (mpesa_sales || 0)
  end
end
