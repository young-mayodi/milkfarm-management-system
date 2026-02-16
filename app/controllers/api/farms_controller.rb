module Api
  class FarmsController < Api::ApplicationController
    def index
      farms = Farm.all
      render json: farms.map { |farm| farm_json(farm) }
    end

    def show
      farm = Farm.find(params[:id])
      render json: farm_json(farm)
    end

    private

    def farm_json(farm)
      {
        id: farm.id,
        name: farm.name,
        owner: farm.owner,
        location: farm.location,
        contact_phone: farm.contact_phone,
        cows_count: farm.cows.count
      }
    end
  end
end
