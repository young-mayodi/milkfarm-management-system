module Api
  class ProductionRecordsController < Api::ApplicationController
    def index
      records = ProductionRecord.all
      records = records.where(farm_id: params[:farm_id]) if params[:farm_id]
      
      if params[:start_date] && params[:end_date]
        records = records.where(production_date: params[:start_date]..params[:end_date])
      end
      
      render json: records.map { |record| record_json(record) }
    end

    def show
      record = ProductionRecord.find(params[:id])
      render json: record_json(record)
    end

    def create
      record = ProductionRecord.new(record_params)
      if record.save
        render json: record_json(record), status: :created
      else
        render json: { errors: record.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      record = ProductionRecord.find(params[:id])
      if record.update(record_params)
        render json: record_json(record)
      else
        render json: { errors: record.errors.full_messages }, status: :unprocessable_entity
      end
    end

    private

    def record_params
      params.require(:production_record).permit(
        :cow_id, :farm_id, :production_date, 
        :morning_production, :noon_production, :evening_production, :night_production
      )
    end

    def record_json(record)
      {
        id: record.id,
        cow_id: record.cow_id,
        cow: {
          id: record.cow.id,
          name: record.cow.name
        },
        farm_id: record.farm_id,
        production_date: record.production_date,
        morning_production: record.morning_production,
        noon_production: record.noon_production,
        evening_production: record.evening_production,
        night_production: record.night_production,
        total_production: record.total_production
      }
    end
  end
end
