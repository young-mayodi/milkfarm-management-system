class AddNightProductionToProductionRecords < ActiveRecord::Migration[8.0]
  def change
    add_column :production_records, :night_production, :decimal
  end
end
