module Api
  class DashboardController < ApplicationController
    def index
      render json: {
        overview_stats: {
          total_farms: Farm.count,
          total_cows: Cow.active.count,
          total_production_records: ProductionRecord.count,
          total_sales_records: SalesRecord.count
        },
        key_metrics: {
          today_production: ProductionRecord.where(production_date: Date.current).sum(:total_production).round(2),
          active_cows: Cow.active.count,
          total_production_this_month: ProductionRecord.where(production_date: Date.current.beginning_of_month..Date.current).sum(:total_production).round(2)
        }
      }
    end
  end
end
