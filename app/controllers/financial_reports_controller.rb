class FinancialReportsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_farm
  before_action :set_date_range

  def index
    @financial_overview = generate_financial_overview
    @quick_stats = generate_quick_stats
    @monthly_trend = generate_monthly_trend
  end

  def profit_loss
    @profit_loss_data = SalesRecord.profit_loss_analysis(@farm, @date_range)
    @monthly_comparison = generate_monthly_comparison
    @expense_breakdown = Expense.breakdown_by_category(@farm, @date_range)

    respond_to do |format|
      format.html
      format.json { render json: @profit_loss_data }
    end
  end

  def cost_analysis
    @cost_breakdown = SalesRecord.cost_breakdown_analysis(@farm, @date_range)
    @expense_breakdown = Expense.breakdown_by_category(@farm, @date_range)
    @cost_per_liter = calculate_cost_per_liter
    @cost_trends = generate_cost_trends

    respond_to do |format|
      format.html
      format.json { render json: { cost_breakdown: @cost_breakdown, expense_breakdown: @expense_breakdown } }
    end
  end

  def roi_report
    @roi_analytics = generate_roi_analytics
    @animal_roi = calculate_animal_roi
    @investment_summary = generate_investment_summary

    respond_to do |format|
      format.html
      format.json { render json: @roi_analytics }
    end
  end

  private

  def set_farm
    @farm = current_user.farm || Farm.first
  end

  def set_date_range
    if params[:period].present?
      case params[:period]
      when "week"
        @date_range = 1.week.ago.to_date..Date.current
      when "month"
        @date_range = 1.month.ago.to_date..Date.current
      when "quarter"
        @date_range = 3.months.ago.to_date..Date.current
      when "year"
        @date_range = 1.year.ago.to_date..Date.current
      else
        @date_range = 1.month.ago.to_date..Date.current
      end
    else
      @date_range = 1.month.ago.to_date..Date.current
    end

    if params[:start_date].present? && params[:end_date].present?
      @date_range = Date.parse(params[:start_date])..Date.parse(params[:end_date])
    end
  end

  def generate_financial_overview
    revenue = SalesRecord.where(farm: @farm, sale_date: @date_range).sum(:total_sales)
    expenses = Expense.total_for_period(@farm, @date_range)
    profit = revenue - expenses
    margin = revenue > 0 ? (profit / revenue * 100) : 0

    {
      total_revenue: revenue.to_f.round(2),
      total_expenses: expenses.to_f.round(2),
      net_profit: profit.to_f.round(2),
      profit_margin: margin.round(2)
    }
  end

  def generate_quick_stats
    production_volume = ProductionRecord.where(farm: @farm, production_date: @date_range).sum(:total_production)
    sales_volume = SalesRecord.where(farm: @farm, sale_date: @date_range).sum(:milk_sold)

    {
      production_volume: production_volume.to_f.round(1),
      sales_volume: sales_volume.to_f.round(1),
      active_cows: @farm.cows.active.count,
      avg_daily_production: production_volume.to_f / ((@date_range.end - @date_range.begin).to_i + 1)
    }
  end

  def generate_monthly_trend
    months_data = {}
    6.times do |i|
      month_start = i.months.ago.to_date.beginning_of_month
      month_end = i.months.ago.to_date.end_of_month

      revenue = SalesRecord.where(farm: @farm, sale_date: month_start..month_end).sum(:total_sales)
      expenses = Expense.total_for_period(@farm, month_start..month_end)

      months_data[month_start.strftime("%b %Y")] = {
        revenue: revenue.to_f.round(2),
        expenses: expenses.to_f.round(2),
        profit: (revenue - expenses).to_f.round(2)
      }
    end
    months_data
  end

  def generate_monthly_comparison
    current_month = Date.current.beginning_of_month..Date.current.end_of_month
    last_month = 1.month.ago.to_date.beginning_of_month..1.month.ago.to_date.end_of_month

    current_data = SalesRecord.profit_loss_analysis(@farm, current_month)
    last_data = SalesRecord.profit_loss_analysis(@farm, last_month)

    {
      current_month: current_data,
      last_month: last_data,
      revenue_change: calculate_percentage_change(current_data[:total_revenue], last_data[:total_revenue]),
      profit_change: calculate_percentage_change(current_data[:gross_profit], last_data[:gross_profit])
    }
  end

  def calculate_cost_per_liter
    total_expenses = Expense.total_for_period(@farm, @date_range)
    total_production = ProductionRecord.where(farm: @farm, production_date: @date_range).sum(:total_production)

    return 0 if total_production <= 0

    (total_expenses / total_production).to_f.round(2)
  end

  def generate_cost_trends
    6.times.map do |i|
      month_start = i.months.ago.to_date.beginning_of_month
      month_end = i.months.ago.to_date.end_of_month

      expenses = Expense.total_for_period(@farm, month_start..month_end)
      production = ProductionRecord.where(farm: @farm, production_date: month_start..month_end).sum(:total_production)
      cost_per_liter = production > 0 ? (expenses / production).round(2) : 0

      {
        month: month_start.strftime("%b %Y"),
        total_expenses: expenses.to_f.round(2),
        cost_per_liter: cost_per_liter
      }
    end.reverse
  end

  def generate_roi_analytics
    investment = Expense.where(farm: @farm, category: [ "equipment", "breeding" ], expense_date: 1.year.ago.to_date..Date.current).sum(:amount)
    annual_profit = SalesRecord.profit_loss_analysis(@farm, 1.year.ago.to_date..Date.current)[:gross_profit]

    roi_percentage = investment > 0 ? ((annual_profit / investment) * 100) : 0

    {
      total_investment: investment.to_f.round(2),
      annual_profit: annual_profit.to_f.round(2),
      roi_percentage: roi_percentage.round(2),
      payback_period: investment > 0 && annual_profit > 0 ? (investment / (annual_profit / 12)).round(1) : 0
    }
  end

  def calculate_animal_roi
    # PERFORMANCE FIX: Use single optimized query instead of N+1
    # Calculate total production per cow in the last 6 months
    cow_production = ProductionRecord
      .where(farm: @farm, production_date: 6.months.ago.to_date..Date.current)
      .group(:cow_id)
      .sum(:total_production)

    # Calculate total revenue for the farm
    total_farm_revenue = SalesRecord
      .where(farm: @farm, sale_date: 6.months.ago.to_date..Date.current)
      .sum(:total_sales)

    # Get total production for the farm
    total_farm_production = cow_production.values.sum
    
    # Calculate ROI for each cow based on their production share
    cows = @farm.cows.active.includes(:production_records)
                .where(production_records: { production_date: 6.months.ago.to_date..Date.current })
                .group('cows.id')
                .limit(20)

    cows.map do |cow|
      cow_total_production = cow_production[cow.id] || 0
      
      # Calculate revenue share based on production
      cow_revenue = if total_farm_production > 0
        (cow_total_production / total_farm_production) * total_farm_revenue
      else
        0
      end

      cow_expenses = 500 * 6 # Estimated 6 months expenses per cow ($500/month)
      cow_profit = cow_revenue - cow_expenses

      {
        name: cow.name,
        tag_number: cow.tag_number,
        revenue: cow_revenue.to_f.round(2),
        estimated_expenses: cow_expenses,
        profit: cow_profit.to_f.round(2),
        roi_percentage: cow_expenses > 0 ? ((cow_profit / cow_expenses) * 100).round(2) : 0
      }
    end
  end

  def generate_investment_summary
    equipment_investment = Expense.where(farm: @farm, category: "equipment", expense_date: 1.year.ago.to_date..Date.current).sum(:amount)
    breeding_investment = Expense.where(farm: @farm, category: "breeding", expense_date: 1.year.ago.to_date..Date.current).sum(:amount)

    {
      equipment_investment: equipment_investment.to_f.round(2),
      breeding_investment: breeding_investment.to_f.round(2),
      total_investment: (equipment_investment + breeding_investment).to_f.round(2)
    }
  end

  def calculate_percentage_change(current, previous)
    return 0 if previous.nil? || previous == 0
    ((current - previous) / previous * 100).round(2)
  end
end
