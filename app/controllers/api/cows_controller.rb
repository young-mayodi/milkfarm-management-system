module Api
  class CowsController < Api::ApplicationController
    def index
      cows = Cow.active
      cows = cows.where(farm_id: params[:farm_id]) if params[:farm_id]
      render json: cows.map { |cow| cow_json(cow) }
    end

    def show
      cow = Cow.find(params[:id])
      render json: cow_json(cow)
    end

    def create
      cow = Cow.new(cow_params)
      if cow.save
        render json: cow_json(cow), status: :created
      else
        render json: { errors: cow.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      cow = Cow.find(params[:id])
      if cow.update(cow_params)
        render json: cow_json(cow)
      else
        render json: { errors: cow.errors.full_messages }, status: :unprocessable_entity
      end
    end

    private

    def cow_params
      params.require(:cow).permit(:name, :tag_number, :breed, :age, :farm_id, :status)
    end

    def cow_json(cow)
      {
        id: cow.id,
        name: cow.name,
        tag_number: cow.tag_number,
        breed: cow.breed,
        age: cow.age,
        status: cow.status,
        farm_id: cow.farm_id,
        group_name: cow.group_name
      }
    end
  end
end
