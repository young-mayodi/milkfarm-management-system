module Api
  class ReportsController < ApplicationController
    def index
      reports = [
        {
          id: 1,
          name: "Production Summary",
          description: "Daily production totals"
        },
        {
          id: 2,
          name: "Sales Report",
          description: "Sales and revenue"
        },
        {
          id: 3,
          name: "Cow Performance",
          description: "Individual cow metrics"
        }
      ]
      render json: reports
    end

    def show
      report_type = params[:id]
      case report_type
      when "1"
        render json: production_summary
      when "2"
        render json: sales_summary
      when "3"
        render json: cow_performance
      else
        render json: { error: "Report not found" }, status: :not_found
      end
    end

    private

    def production_summary
      {
        id: 1,
        name: "Production Summary",
        total_production: ProductionRecord.sum(:total_production),
        average_per_cow: (ProductionRecord.sum(:total_production).to_f / Cow.active.count).round(2),
        farms: Farm.all.map { |farm|
          {
            name: farm.name,
            total_production: farm.production_records.sum(:total_production),
            cow_count: farm.cows.active.count
          }
        }
      }
    end

    def sales_summary
      {
        id: 2,
        name: "Sales Report",
        total_sales: SalesRecord.sum(:cash_sales) + SalesRecord.sum(:mpesa_sales),
        total_milk_sold: SalesRecord.sum(:milk_sold),
        sales_by_farm: Farm.all.map { |farm|
          sales = farm.sales_records
          {
            farm: farm.name,
            total_amount: (sales.sum(:cash_sales) + sales.sum(:mpesa_sales)),
            milk_sold: sales.sum(:milk_sold)
          }
        }
      }
    end

    def cow_performance
      {
        id: 3,
        name: "Cow Performance",
        top_producers: Cow.active.map { |cow|
          production = cow.production_records.sum(:total_production)
          {
            name: cow.name,
            average_daily: (production.to_f / [cow.production_records.count, 1].max).round(2),
            total_production: production
          }
        }.sort_by { |c| -c[:average_daily] }.first(10)
      }
    end
  end
end
